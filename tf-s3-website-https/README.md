# tf-s3-website-https

CloudFront + S3 を使った HTTPS 静的ウェブサイトホスティング環境を Terraform で構築する。

## アーキテクチャ

```
ユーザー
  │
  │ HTTPS
  ▼
CloudFront（デフォルトドメイン: xxxxxxx.cloudfront.net）
  │
  │ OAC（Origin Access Control）
  ▼
S3 バケット（非公開）
  └── index.html
  └── error.html
  └── assets/...
```

## main.tf の構成

### 1. S3 バケット（非公開）

- `aws_s3_bucket` — サイトファイルを格納するバケットを作成
- `aws_s3_bucket_public_access_block` — パブリックアクセスを**完全にブロック**（直接 URL では 403 になる）
- `aws_s3_bucket_policy` — CloudFront OAC からのアクセス**のみ**を許可するバケットポリシー

### 2. CloudFront ディストリビューション

- `aws_cloudfront_origin_access_control` — OAC を作成し、CloudFront → S3 へのリクエストに SigV4 署名を付与
- `aws_cloudfront_distribution` — CDN ディストリビューションを作成
  - **HTTP → HTTPS 自動リダイレクト** (`redirect-to-https`)
  - **gzip 圧縮有効** (`compress = true`)
  - **デフォルトルートオブジェクト**: `index.html`
  - **カスタムエラーレスポンス**: 403/404 → `error.html` を返す
  - **SSL 証明書**: CloudFront デフォルト証明書（`*.cloudfront.net`）

### 3. サイトファイルのアップロード

- `aws_s3_object` — `../site/` ディレクトリ配下の全ファイルを S3 にアップロード
- 拡張子に応じた `Content-Type` を自動設定（html, css, js, json, png, jpg, svg, ico）

### 4. Outputs

| 出力名 | 内容 |
|---|---|
| `bucket_name` | S3 バケット名 |
| `cloudfront_distribution_id` | CloudFront ディストリビューション ID |
| `website_url` | HTTPS でアクセスできる URL |
| `s3_direct_url` | S3 直アクセス URL（403 になることを確認用） |

## tf-s3-website との違い

| 項目 | tf-s3-website | tf-s3-website-https |
|---|---|---|
| S3 アクセス | パブリック公開 | 非公開（OAC 経由のみ） |
| 配信方法 | S3 Website Endpoint (HTTP) | CloudFront (HTTPS) |
| HTTP → HTTPS | なし | 自動リダイレクト |
| キャッシュ / 圧縮 | なし | CloudFront による CDN キャッシュ + gzip |

## 使い方

```bash
cd tf-s3-website-https
terraform init
terraform plan
terraform apply
```

デプロイ完了後、`website_url` に表示される URL でサイトにアクセスできる。

> **注意**: CloudFront ディストリビューションのデプロイには 5〜15 分ほどかかる。

## 削除

```bash
terraform destroy
```
