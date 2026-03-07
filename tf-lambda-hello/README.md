# tf-lambda-hello

Terraform だけで Lambda を作成し、Function URL で動作確認できる最小構成。

## 作るもの

- `aws_lambda_function` で Python Lambda を 1 本作成
- `archive_file` で `lambda_function.py` を zip 化
- `aws_lambda_function_url` でブラウザや `curl` から直接呼び出せる URL を作成
- `aws_cloudwatch_log_group` でログ保存先を明示

## 実行手順

```bash
cd tf-lambda-hello
terraform init
terraform plan
terraform apply
```

適用後、`function_url` が出力される。

```bash
curl "$(terraform output -raw function_url)"
```

## 削除

```bash
terraform destroy
```

## 補足

- zip 作成は Terraform の `archive_file` で行うため、別途 zip コマンドは不要
- `authorization_type = "NONE"` のため、学習用としては触りやすいが、公開 URL になる点には注意