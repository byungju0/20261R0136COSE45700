# Module: s3-archive

크롤링 원본 HTML 보관용 S3 버킷.

## 보안 baseline

| 설정 | 값 | 룰 |
|---|---|---|
| public access block | 4종 모두 true | `CKV_AWS_53/54/55/56` |
| versioning | enabled | `CKV_AWS_21` |
| SSE | `aws:kms` (region default) | `CKV_AWS_145` |
| bucket key | enabled (KMS 비용 절감) | — |
| TLS-only policy | `aws:SecureTransport = false` deny | — |
| access logging | optional (Task 8 CloudTrail 버킷에 적재) | `CKV_AWS_18` |

## Lifecycle

| 단계 | 시점 |
|---|---|
| `STANDARD_IA` 전환 | 90일 |
| 객체 삭제 | 365일 |
| 비최신 버전 삭제 | 30일 |
| 미완료 멀티파트 정리 | 7일 |

→ 학생 예산 보호 + Story 1.4 데이터 보관 정책.

## Bucket policy

- **Allow**: Crawler IAM Role의 `s3:PutObject`/`PutObjectAcl`/`AbortMultipartUpload`
- **Allow**: Crawler IAM Role의 `s3:ListBucket`
- **Deny (모든 Principal)**: 비-TLS 접근

→ 외부 모든 Principal은 **암묵적 Deny**(IAM의 default deny). 명시적 Allow가 Crawler Role에만 있어 Principal 제한이 IAM과 bucket policy 양쪽에서 보장된다.

## 버킷 이름 충돌 방지

`{prefix}-{env}-{random_id_4byte_hex}` 패턴으로 글로벌 unique 보장.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
