## Spacelift

```bash
source /mnt/workspace/aws_credentials; terraform show -json | gzip | aws --profile spacelift s3 cp - "s3://dn-spacelift-test/${TF_VAR_spacelift_stack_id}.gz"
```
