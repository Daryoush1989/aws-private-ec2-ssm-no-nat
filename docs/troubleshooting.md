# Troubleshooting

## Session Manager fails due to CloudWatch Logs encryption
### Symptoms
- Starting a Session Manager session fails.
- Error mentions that encryption is not set up on the selected CloudWatch Logs log group.

### Cause
- This is caused by an account-level Systems Manager Session Manager Preference.
- CloudWatch session logging was enabled in Session Manager preferences with encryption requirements, but the selected CloudWatch Logs log group was not encrypted.
- Session Manager does NOT require CloudWatch Logs to function.

### Fix (recommended: disable logging)
1. Go to AWS Systems Manager
2. Left menu → Session Manager
3. Preferences tab → Edit
4. Disable CloudWatch logging (and S3 logging if enabled)
5. Save
6. Retry the session:
   - Console: Session Manager → Start session
   - CLI: aws ssm start-session --target <instance-id> --region eu-west-2

### Alternative fix (if you want to keep CloudWatch logging)
- Systems Manager → Session Manager → Preferences → Edit
- Enable CloudWatch logging
- Choose an existing log group or create one
- Ensure "Encrypt log data" is OFF (no KMS key selected), OR encrypt the log group with a KMS key that is correctly configured.
