# Calculator enum fields are unusable from the app — diagnosed 2026-10-01

## The symptom, observed on a real device

`civil/beam-deflection` is one of the most-used calculators in the product. A
user fills in four numbers, reaches the beam type, and gets:

> The selected beam type is invalid.

They typed "Simply Supported", which is the name the enum itself uses for
display. It is rejected. So is "fixedy", which is what the keyboard's autocorrect
turns "fixed" into. There is no way for a user to succeed without knowing the
literal wire value `simply_supported`, and nothing on screen tells them that.

## Root cause: the contract is declared in one place and validated in another

The **request** validates against the enum:

```php
// app/Domains/Calculator/Civil/Http/Requests/CalculateBeamDeflectionRequest.php:28
'beam_type' => ['required', Rule::enum(BeamType::class)],
```

```php
// app/Domains/Calculator/Civil/Enums/BeamType.php
case SIMPLY_SUPPORTED = 'simply_supported';
case CANTILEVER      = 'cantilever';
case FIXED           = 'fixed';
case CONTINUOUS      = 'continuous';
```

The **field metadata** the client renders from advertises it as free text:

```json
{ "name": "beam_type", "type": "text", "required": true, "options": null }
```

So the client is told "any text is fine" and the server insists on one of four
exact strings. `options` is the field the app uses to decide between a text box
and a dropdown, and it is `null` everywhere it matters.

## This is not one calculator

18 enum-validated fields across 16 request classes:

| Request | Field | Enum |
|---|---|---|
| CalculateBeamDeflectionRequest | beam_type | BeamType |
| CalculateBrickRequest | wall_thickness | WallThickness |
| CalculateConcreteMixRequest | concrete_type | ConcreteType |
| CalculateFoundationDesignRequest | soil_type | SoilType |
| CalculateBatteryRequest | system_voltage | SystemVoltage |
| CalculateConduitScheduleRequest | conduit_type | ConduitType |
| CalculateConduitSizeRequest | conduit_type | ConduitType |
| CalculateEarthingRequest | soil_type | SoilType |
| CalculateEarthingRequest | electrode_type | ElectrodeType |
| CalculateGeneratorRequest | load_type | GeneratorLoadType |
| CalculateSolarRequest | panel_type | SolarPanelType |
| CalculateEmergencyExitRequest | building_use | BuildingUse |
| CalculateEmergencyExitRequest | hazard_type | HazardType |
| CalculateExtinguisherRequest | fire_class | FireClass |
| CalculateExtinguisherRequest | hazard_level | HazardLevel |
| CalculateFireAlarmRequest | detector_type | DetectorType |
| CalculateSprinklerRequest | occupancy_type | OccupancyType |
| CalculateSprinklerRequest | hazard_classification | HazardClassification |

Spot-checked live and both advertise `type: "text"`, `options: null`:
`civil/concrete-mix-design` → `concrete_type`, `civil/foundation-design` →
`soil_type`.

## Fix

Populate `options` for every enum-backed field, using the enum's own cases, so
the app renders a dropdown. The shape the client already understands:

```json
{ "name": "beam_type", "type": "select", "required": true,
  "options": [
    { "value": "simply_supported", "label": "Simply Supported Beam" },
    { "value": "cantilever",      "label": "Cantilever Beam" },
    { "value": "fixed",           "label": "Fixed Beam" },
    { "value": "continuous",      "label": "Continuous Beam" }
  ] }
```

`BeamType` already has the display strings
(`self::SIMPLY_SUPPORTED => 'Simply Supported Beam'`), so the labels do not have
to be written by hand.

The important part is that `type` must change from `text` to a select type.
Leaving `options` populated on a `text` field is worse than leaving it null,
because the client would still show a text box and only hint at the values.

## Then add the regression test

A test that walks every `Calculate*Request` with a `Rule::enum` rule and asserts
the corresponding field metadata carries a non-null `options` with at least as
many entries as the enum has cases. Without it the next calculator added repeats
this, and the failure mode is invisible until a user tries it.

## Client side: do not work around it

The app deliberately renders whatever `type` and `options` the server sends. It
must not hardcode a dropdown for `beam_type`, because the server owns the enum
and may add cases. Fixing this in the client would hardcode a second source of
truth for 18 fields and still miss the next calculator.