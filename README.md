## This is a project created for me to play with terraform and rust

To run this project you must first build the rust project by running
```
cargo build --release --target x86_64-unknown-linux-musl
```
in the `hello_lambda` directory to cross compile the project for the lambda platform.

After that, in the `hello_world_tf` directory run:
```
terraform init

terraform apply
```

You must have valid AWS credentials configured

The created lambda function will write the body parameter from the event to a file in the S3 bucket given as an enviromnet variable.

Sample execution:
```
$ aws lambda invoke --function-name HelloWorld --cli-binary-format raw-in-base64-out --payload '{"body": "It works?"}' output.txt

{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}

$ cat output.txt

{"body":"the lambda has successfully stored the your request in S3 with name '1647707844.txt'"}

$ aws s3api get-object --bucket ppetrica-bucket-2 --key 1647707844.txt test.txt
{
    "AcceptRanges": "bytes",
    "LastModified": "2022-03-19T16:37:26+00:00",
    "ContentLength": 9,
    "ETag": "\"9f2c76944412d459ec771dd7f93fc36b\"",
    "ContentType": "text/plain",
    "Metadata": {}
}

$ cat test.txt 
It works?

```

