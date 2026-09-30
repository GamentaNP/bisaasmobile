# Syllabus question mapping — diagnosed 2026-09-30

> **Owner: server.** This is a content/data task in `C:\laragon\www\bisaas`, not a
> client task. It is recorded here because it is the largest gap blocking the
> product, and because the client already behaves correctly around it. Nothing in
> `bisaasmobile` can close it.

## The symptom

`quiz_question_syllabus_node` has **0 rows**. The syllabus tree renders perfectly in
the app (542 nodes for `lok-sewa-sub-engineer-2026`, correct blueprint, correct
marks), but a learner who opens a topic finds there is nothing to practise on.

This is the single largest content gap in the product. It is a **server** task.

## Why it is not "just run the command"

`php artisan syllabus:backfill-mappings lok-sewa-sub-engineer-2026 --dry-run`
already exists and does run. Its output:

```
linked categories           3
ambiguous topics            16
general-learning categories 11
derived question mappings   0
```

Zero derived mappings. Four distinct causes, all verified against the live database.

## Root cause 1 — 737 nodes are orphaned

```
syllabus_version_id IS NULL   ->  737 nodes (59 of them units)
syllabus_version_id = 8       ->  542 nodes
```

The command filters `->where('syllabus_version_id', $version->id)`, so it can
never see the 737 orphans. Those are the `legacy-<id>` nodes whose `path` is the
placeholder `legacy-8867` rather than a real outline path.

**Fix:** decide whether the orphans are legacy duplicates of the v8 tree or a
second exam. If duplicates, soft-delete them. If a second exam, give them a
`syllabus_version_id`. Do not leave them invisible to every command that filters
by version — that is how this silently rotted.

## Root cause 2 — 81 of 85 units have no `quiz_category_id`

```
units with no quiz_category_id      81   (22 of them in v8)
v8 units with no quiz_category_id   22
```

The command's step 1 links unit -> category by name. It linked only 3.

## Root cause 3 — the catalog topic names do not carry outline codes

The command's primary match looks for an official code prefix in the topic name
(`/^(\d{1,2}\.\d{1,2}(\.\d{1,2})?)\./`). The seeded catalog names do not have one:

```
'Planning - Topic 1'          -> 'Construction Management'  (score 0.31)
'Project Management - Topic 2'-> 'Construction Management'  (score 0.303)
```

Every topic is literally `"<Subject> - Topic <N>"`. The fallback is
`TitleSimilarity >= 0.92` against the unit's subtree, and `"Planning - Topic 1"`
has nothing in common with any real node title, so it scores ~0.31 and is
rejected as ambiguous. The 0.92 threshold is doing its job; the input is wrong.

## Root cause 4 — the real join key is `quiz_categories.name`, and it works

This is the important finding. Category names match syllabus unit titles exactly:

```
category                  node_title                node_type  questions  topics
Construction Management   Construction Management   unit       192        16
Soil Mechanics            Soil Mechanics            unit       14         0
Surveying                 Surveying                 unit       15         0
Estimating and Costing    Estimating and Costing    unit       15         0
Highway Engineering       Highway Engineering       unit       3          0
```

`lower(btrim(category.name)) = lower(btrim(node.title))` is a clean, exact join
over real data — no fuzzy matching, no invention. A category -> unit link of this
kind gives every question in that category a syllabus node via
`quiz_questions.quiz_category_id`, which is populated on **10,619 of 10,629**
questions.

## What NOT to do

Do **not** map questions to nodes by fuzzy-matching topic names. I tried it and
measured it:

| Rule | Questions reached | Verdict |
|---|---|---|
| `node.title` = topic name, exact | 672 | safe, far too small |
| topic slug `LIKE '%node-slug%'` | 6,720 | **unsafe** |
| slug, segment-anchored | 6,624 | **still unsafe** |

The substring rules look far better on paper and are wrong. `"Design"` matches 48
topics, including `beam-design` and `machine-design`, and a syllabus node titled
`General` matches `medical-pharmacology-general-topic-1` through `-4` — 192
questions attached to a node that has nothing to do with them. The 63% coverage
is an artefact of short generic words appearing inside unrelated slugs.

A wrong mapping is worse than no mapping: it shows a learner a Soil Mechanics
question under Pharmacology and destroys trust in the whole bank. Use the exact
category join, or a curated mapping table reviewed by someone who knows the
syllabus.

## Recommended sequence

1. Resolve the 737 orphaned nodes (root cause 1). Everything else is noisy until
   this is settled.
2. Backfill `quiz_syllabus_nodes.quiz_category_id` from the exact
   `category.name = node.title` join, restricted to `node_type = 'unit'`.
   Verify the duplicate-title cases by hand first — `Construction Management`
   appears at two node ids (10943, 11196) and two category ids (168, 245).
3. Only then run the existing backfill, which will have real categories to work
   from. Prefer a curated `quiz_syllabus_node_topic` table over fuzzy matching.
4. Verify with: every examinable v8 node has `question_count > 0` where content
   exists, and zero questions mapped to a node whose title is unrelated to the
   question's category.

## Client impact meanwhile

The app already handles this honestly: `Syllabus` is offered because it has
content, and a topic with no questions shows an empty state rather than an
error. This is a content gap, not a client defect, and no client change will
close it.
