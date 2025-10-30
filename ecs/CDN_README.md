# Image CDN Setup (S3 + CloudFront)

This Terraform configuration sets up a CDN for serving images publicly using Amazon S3 and CloudFront.

## Architecture

- **S3 Bucket**: Stores all image files
- **CloudFront Distribution**: CDN for fast, global delivery of images
- **Origin Access Control (OAC)**: Secure access from CloudFront to S3
- **IAM Policies**: ECS tasks can upload/delete images from the bucket

## Features

- ✅ Publicly readable images via CloudFront
- ✅ HTTPS enforced (redirects HTTP to HTTPS)
- ✅ CORS enabled for web applications
- ✅ Compressed content delivery
- ✅ Global CDN with caching (1 day default, 1 year max)
- ✅ ECS task permissions to manage images

## Usage

### Uploading Images

From your ECS application, use the AWS SDK to upload images to S3:

```python
import boto3

s3_client = boto3.client('s3')
bucket_name = 'neatqueue-images'  # or use Terraform output

# Upload an image
with open('image.jpg', 'rb') as f:
    s3_client.put_object(
        Bucket=bucket_name,
        Key='uploads/image.jpg',
        Body=f,
        ContentType='image/jpeg'
    )
```

```javascript
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

// Upload an image
const params = {
    Bucket: 'neatqueue-images',  // or use Terraform output
    Key: 'uploads/image.jpg',
    Body: fileBuffer,
    ContentType: 'image/jpeg'
};

await s3.upload(params).promise();
```

### Accessing Images

Once uploaded, images are accessible via CloudFront:

```
https://{cloudfront-domain}/uploads/image.jpg
```

The CloudFront domain is available as a Terraform output:
```bash
terraform output cdn_domain_name
# or
terraform output cdn_url
```

### Example URLs

- Direct image: `https://d1234567890abc.cloudfront.net/uploads/profile.jpg`
- Subdirectory: `https://d1234567890abc.cloudfront.net/products/item-123.png`

## Cache Behavior

- **Default TTL**: 1 day (86,400 seconds)
- **Maximum TTL**: 1 year (31,536,000 seconds)
- **Compression**: Enabled automatically for supported content types

### Invalidating Cache

If you need to invalidate cached content:

```bash
aws cloudfront create-invalidation \
    --distribution-id YOUR_DISTRIBUTION_ID \
    --paths "/path/to/image.jpg" "/*"
```

Get the distribution ID from Terraform outputs:
```bash
terraform output -json | jq -r '.cdn_distribution_id.value'
```

## Terraform Outputs

After deployment, these values are available:

- `cdn_domain_name`: CloudFront distribution domain
- `cdn_url`: Full HTTPS URL to the CDN
- `images_bucket_name`: S3 bucket name
- `images_bucket_arn`: S3 bucket ARN

## Security

- S3 bucket is **not directly publicly accessible**
- Images are served only through CloudFront
- CloudFront uses Origin Access Control (OAC) to access S3
- HTTPS is enforced (HTTP requests redirect to HTTPS)
- ECS tasks have explicit IAM permissions for bucket operations

## Cost Optimization

- Using `PriceClass_100` (North America & Europe only) for lower costs
- Consider changing to `PriceClass_All` if you need global distribution

## Monitoring

Monitor CloudFront metrics in AWS Console:
- Requests
- Data Transfer
- Error Rates
- Cache Hit Ratio

## Next Steps

1. Deploy this configuration: `terraform apply`
2. Note the CloudFront URL from outputs
3. Update your application to use the S3 bucket for uploads
4. Access images via the CloudFront URL
5. (Optional) Set up a custom domain with Route53 and ACM certificate

