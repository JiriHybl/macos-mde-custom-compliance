# macOS Microsoft Defender Custom Compliance

A Bash discovery script and Microsoft Intune custom compliance rules for checking
Microsoft Defender for Endpoint (MDE) on macOS.

The script collects Defender status without changing device settings. The supplied
policy requires Defender to report that it is healthy.

## Files

| File | Purpose |
| --- | --- |
| [`mdecompliance.sh`](mdecompliance.sh) | Queries the local Defender CLI and prints one JSON object. |
| [`rules.json`](rules.json) | Defines the Intune compliance requirement and user-facing remediation message. |

## How it works

The script checks whether `/usr/local/bin/mdatp` exists and is executable. If it
does, it queries Defender health fields and the threat list, then returns these
case-sensitive JSON properties:

| Property | Type | Meaning |
| --- | --- | --- |
| `MdeInstalled` | Boolean | Whether the Defender CLI exists and is executable at the configured path. |
| `MdeHealthy` | Boolean | Whether `mdatp health --field healthy` returns `true`. |
| `RtpEnabled` | Boolean | Whether `mdatp health --field real_time_protection_enabled` returns `true`. |
| `DefAgeMinutes` | Integer | Minutes since the last definition update, from `definitions_updated_minutes_ago`. |
| `ActiveThreats` | Integer | Case-insensitive count of lines containing `threat id` in `mdatp threat list` output. See limitations below. |

Example output when Defender reports healthy status:

```json
{"MdeInstalled":true,"MdeHealthy":true,"RtpEnabled":true,"DefAgeMinutes":30,"ActiveThreats":0}
```

If the Defender CLI is missing or not executable, the script returns:

```json
{"MdeInstalled":false,"MdeHealthy":false,"RtpEnabled":false,"DefAgeMinutes":999999,"ActiveThreats":999}
```

Boolean health values other than the literal `true` are reported as `false`.
A missing or nonnumeric definition age is reported as `999999`.
The script exits with code `0` after reporting discovery data; Intune determines
compliance from the JSON values, not from that exit code.

## Compliance rule

The supplied `rules.json` contains **one rule: `MdeHealthy` must equal `true`**.
The other four properties are reported but have no independent compliance rules.
In particular, this policy does not separately enforce real-time protection,
definition freshness, or a zero-threat threshold.

When Defender is not healthy, the English (`en_US`) remediation message is:

- **Title:** Defender is not healthy
- **Description:** Contact IT support.

The rule also links to Microsoft's Defender for Endpoint on macOS documentation.
To enforce additional properties, add matching rules to `rules.json`, using the
exact property names and corresponding Boolean or `Int64` data types.

## Requirements

- A macOS device enrolled in Microsoft Intune with custom compliance available.
  Microsoft notes that macOS custom compliance availability in special clouds
  can differ; check the current documentation linked below.
- Microsoft Defender for Endpoint installed and configured, with the CLI at
  `/usr/local/bin/mdatp`. Adjust the script's `M` variable if your installation
  uses a different path.
- Bash, available at `/bin/bash` on macOS, and standard command-line utilities.
- An Intune administrator with permission to add compliance scripts and policies.

## Test on a Mac

Download or clone this repository, open Terminal in its directory, and run:

```bash
/bin/bash -n mdecompliance.sh
/bin/bash mdecompliance.sh
```

The second command should print a single JSON object with the properties above.
Compare the values with local Defender diagnostics:

```bash
/usr/local/bin/mdatp health
/usr/local/bin/mdatp threat list
```

Test under the same execution context that you plan to configure in Intune.
An exit code of `0` means discovery completed, not that the device is compliant.

## Deploy with Microsoft Intune

1. In the [Intune admin center](https://intune.microsoft.com/), go to
   **Endpoint security > Device compliance > Scripts > Add**, and select macOS.
2. Name the discovery script and upload `mdecompliance.sh`. Review the execution
   context and signature settings. This sample is unsigned; a configuration that
   requires a valid signature needs a suitably signed version.
3. Create or edit a macOS compliance policy. In its custom compliance settings,
   select the discovery script and upload `rules.json`.
4. Assign the policy to a pilot group and review per-setting compliance results
   before expanding the assignment.
5. After resolving an issue, users can open Company Portal, select **Devices**,
   select their Mac, and choose **Check Status**.

Keep the script UTF-8 encoded without a byte-order mark and use LF line endings.
The repository's `.gitattributes` enforces LF for shell scripts on checkout.

## Limitations

- This is a read-only discovery sample, not a remediation script. It does not
  install, onboard, update, or repair Defender.
- `MdeInstalled` detects an executable CLI, not successful onboarding or licensing.
- `ActiveThreats` parses human-readable CLI output and does not distinguish
  active threats from historical or remediated entries. A failed threat-list
  command can produce a count of `0` because its errors are suppressed. Do not
  treat this field as a fail-closed, active-threat assessment.
- Defender query errors are not logged by this script. Failed health queries
  result in `false`, and an invalid definition age uses the sentinel described
  above. The threat-count fallback of `999` only applies to a nonnumeric count.
- CLI output and permissions can vary by Defender version and execution context.
  Validate the sample on representative Macs before production use.

## References

- [Intune custom compliance settings](https://learn.microsoft.com/en-us/intune/device-security/compliance/custom-settings)
- [Create custom compliance discovery scripts](https://learn.microsoft.com/en-us/intune/device-security/compliance/create-custom-script)
- [Create custom compliance JSON rules](https://learn.microsoft.com/en-us/intune/device-security/compliance/create-custom-json)
- [Microsoft Defender for Endpoint on macOS](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint-mac)
