# ADR 0007 — Record facts and revision history

Accepted for the isolated v4 store. Production composition remains gated.

Drift v4 retains the original UTC instant, offset in minutes and device
timezone identifier on new medication events. It uses the browser or
platform timezone identifier when available and a device label otherwise.
Existing entries stay null where the original zone was unavailable. An
optional scheduled occurrence link stores the intended instant and a stable
regimen and civil-slot key. Device-local schedule evaluation skips missing
clock minutes and takes the first instant of a repeated clock minute.
Travelling changes the instant of a future device-local slot while keeping
its key. Scheduled, overdue and explicit outcomes remain separate.

The local audit table stores encrypted, versioned prior catalogue and
symptom values. Symptom revisions replace the current entry and its markers
in the same transaction as appending the prior snapshot. Regimen revisions
close the earlier effective range and insert a new regimen and rules in one
transaction. Existing administration snapshots retain their original
prescribed context. Current event selection, timings, and linked
occurrences remain explicit.

The exported v3 schema generated a measurement constraint with a zero upper
bound from the previous maximum floating-point literal. The v4 migration
rebuilds that table and copies any valid existing values, with a constraint
that rejects non-positive and non-finite values. Source snapshots, DDL
transactions, and version stamping use the recovery workflow in ADR 0006.
