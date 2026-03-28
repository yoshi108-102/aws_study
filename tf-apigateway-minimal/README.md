# tf-apigateway-minimal

API Gateway (HTTP API) + Lambda の最小構成を Terraform で作成するサンプル。

この構成では AWS Lambda Powertools (Logger) を利用して JSON 形式の構造化ログを CloudWatch Logs に出力する。

## 構成

- API Gateway HTTP API
- Lambda (Python 3.12)
- GET `/hello`
- POST `/echo`
- CloudWatch Logs (Lambda の基本実行ロール)

## 事前条件

- AWS 認証情報が利用可能であること
- Terraform 1.5 以上

## 使い方

```bash
cd tf-apigateway-minimal
terraform init
terraform apply
```

必要に応じてログレベルを変更する場合:

```bash
terraform apply -var 'powertools_log_level=DEBUG'
```

適用後に出力される URL で動作確認。

```bash
# 1) GET /hello
curl "$(terraform output -raw hello_url)"

# 2) POST /echo
curl -X POST "$(terraform output -raw echo_url)" \
  -H "content-type: application/json" \
  -d '{"name":"yoshi","purpose":"apigw test"}'
```

## 片付け

```bash
terraform destroy
```

## メモ

- CORS は最小設定で有効化済み (`*`)。
- 学習用の最小構成なので、実運用では認証やアクセス制御の追加を推奨。

## CloudWatch Logs Insights 例

最近のログを確認:

```sql
fields @timestamp, level, message, method, path, correlation_id
| sort @timestamp desc
| limit 100
```

エラー/警告のみ確認:

```sql
fields @timestamp, level, message, method, path, correlation_id
| filter level = "ERROR" or level = "WARNING"
| sort @timestamp desc
| limit 100
```
