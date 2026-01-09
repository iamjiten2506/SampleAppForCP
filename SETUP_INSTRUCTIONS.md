# Manual CI/CD Setup Instructions

Follow these steps to create a CI/CD pipeline using AWS Console and GitHub.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **GitHub Account** and repository
3. **EC2 Key Pair** created in your AWS region

## Step 1: Create GitHub Repository

1. Go to GitHub and create a new repository
2. Upload all files from the `simple-cicd-app` folder to your repository
3. Note your repository URL: `https://github.com/YOUR_USERNAME/YOUR_REPO_NAME`

## Step 2: Create GitHub Personal Access Token

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Select scopes: `repo` (Full control of private repositories)
4. Copy the token - you'll need it later

## Step 3: Create EC2 Instance for Deployment

### 3.1 Launch EC2 Instance
1. Go to **EC2 Console** → Launch Instance
2. **Name**: `cicd-demo-server`
3. **AMI**: Amazon Linux 2 AMI
4. **Instance Type**: t2.micro (free tier eligible)
5. **Key Pair**: Select your existing key pair
6. **Security Group**: Create new with these rules:
   - SSH (22) from your IP
   - HTTP (80) from anywhere (0.0.0.0/0)
   - Custom TCP (3000) from anywhere (0.0.0.0/0)

### 3.2 Tag the Instance
1. Add tag: `Key: Name`, `Value: cicd-demo-server`
2. Add tag: `Key: Environment`, `Value: demo`

### 3.3 Create IAM Role for EC2
1. Go to **IAM Console** → Roles → Create Role
2. **Service**: EC2
3. **Policies**: Attach `AmazonEC2RoleforAWSCodeDeploy`
4. **Role Name**: `EC2-CodeDeploy-Role`
5. Go back to EC2 → Select your instance → Actions → Security → Modify IAM Role
6. Attach the `EC2-CodeDeploy-Role`

## Step 4: Create S3 Bucket for Artifacts

1. Go to **S3 Console** → Create Bucket
2. **Name**: `your-cicd-artifacts-bucket-RANDOM_NUMBER` (must be globally unique)
3. **Region**: Same as your EC2 instance
4. Keep default settings and create

## Step 5: Create CodeBuild Project

### 5.1 Create CodeBuild Service Role
1. Go to **IAM Console** → Roles → Create Role
2. **Service**: CodeBuild
3. **Policies**: 
   - `AWSCodeBuildDeveloperAccess`
   - Create inline policy for S3 access:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:PutObject"
         ],
         "Resource": "arn:aws:s3:::your-cicd-artifacts-bucket-*/*"
       }
     ]
   }
   ```
4. **Role Name**: `CodeBuild-Service-Role`

### 5.2 Create CodeBuild Project
1. Go to **CodeBuild Console** → Create Project
2. **Project Name**: `cicd-demo-build`
3. **Source Provider**: GitHub
4. **Repository**: Connect to your GitHub repository
5. **Environment**:
   - **Image**: Amazon Linux 2
   - **Runtime**: Standard
   - **Image Version**: Latest
6. **Service Role**: Use existing `CodeBuild-Service-Role`
7. **Buildspec**: Use a buildspec file (it will use the `buildspec.yml` in your repo)
8. Create project

## Step 6: Create CodeDeploy Application

### 6.1 Create CodeDeploy Service Role
1. Go to **IAM Console** → Roles → Create Role
2. **Service**: CodeDeploy
3. **Use Case**: CodeDeploy
4. **Policy**: `AWSCodeDeployRole` (automatically attached)
5. **Role Name**: `CodeDeploy-Service-Role`

### 6.2 Create CodeDeploy Application
1. Go to **CodeDeploy Console** → Applications → Create Application
2. **Application Name**: `cicd-demo-app`
3. **Compute Platform**: EC2/On-premises
4. Create application

### 6.3 Create Deployment Group
1. In your application → Create Deployment Group
2. **Name**: `cicd-demo-deployment-group`
3. **Service Role**: `CodeDeploy-Service-Role`
4. **Deployment Type**: In-place
5. **Environment Configuration**: Amazon EC2 instances
6. **Tag Group**: 
   - Key: `Environment`
   - Value: `demo`
7. **Load Balancer**: Uncheck (not needed for demo)
8. Create deployment group

## Step 7: Create CodePipeline

### 7.1 Create CodePipeline Service Role
1. Go to **IAM Console** → Roles → Create Role
2. **Service**: CodePipeline
3. **Policy**: `AWSCodePipelineFullAccess`
4. Add inline policy for additional permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketVersioning",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild",
        "codedeploy:CreateDeployment",
        "codedeploy:GetApplication",
        "codedeploy:GetApplicationRevision",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision"
      ],
      "Resource": "*"
    }
  ]
}
```
5. **Role Name**: `CodePipeline-Service-Role`

### 7.2 Create Pipeline
1. Go to **CodePipeline Console** → Create Pipeline
2. **Pipeline Name**: `cicd-demo-pipeline`
3. **Service Role**: `CodePipeline-Service-Role`
4. **Artifact Store**: Your S3 bucket

### 7.3 Add Source Stage
1. **Source Provider**: GitHub (Version 1)
2. **Repository**: Your repository
3. **Branch**: main
4. **GitHub Token**: Paste your personal access token
5. **Output Artifacts**: SourceOutput

### 7.4 Add Build Stage
1. **Build Provider**: AWS CodeBuild
2. **Project Name**: `cicd-demo-build`
3. **Input Artifacts**: SourceOutput
4. **Output Artifacts**: BuildOutput

### 7.5 Add Deploy Stage
1. **Deploy Provider**: AWS CodeDeploy
2. **Application Name**: `cicd-demo-app`
3. **Deployment Group**: `cicd-demo-deployment-group`
4. **Input Artifacts**: BuildOutput

### 7.6 Review and Create
1. Review all settings
2. Create pipeline

## Step 8: Test the Pipeline

1. **Trigger Pipeline**: Push a change to your GitHub repository
2. **Monitor**: Watch the pipeline execute in CodePipeline console
3. **Verify**: 
   - Check EC2 instance: `http://YOUR_EC2_PUBLIC_IP:3000`
   - Health check: `http://YOUR_EC2_PUBLIC_IP:3000/health`

## Troubleshooting

### Common Issues:

1. **CodeDeploy Agent**: SSH to EC2 and check:
   ```bash
   sudo service codedeploy-agent status
   sudo service codedeploy-agent start
   ```

2. **Permissions**: Ensure all IAM roles have correct policies

3. **Security Groups**: Verify ports 22, 80, and 3000 are open

4. **Application Logs**: Check `/var/log/myapp.log` on EC2

## Next Steps

- Add automated tests to the build stage
- Implement blue/green deployments
- Add monitoring and alerts
- Set up multiple environments (staging, production)

## Cleanup

To avoid charges:
1. Delete CodePipeline
2. Delete CodeBuild project
3. Delete CodeDeploy application
4. Terminate EC2 instance
5. Delete S3 bucket
6. Delete IAM roles