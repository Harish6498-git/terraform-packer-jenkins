pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-2'
        TF_DIR = 'terraform/terraform-infra'
        PKR_DIR = 'packer'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init & Validate') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        rm -rf .terraform .terraform.lock.hcl || true
                        terraform init
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform plan -out=tfplan.out'
                }
            }
        }

        stage('Terraform Apply (VPC + RDS)') {
            steps {
                dir("${TF_DIR}") {
                    timeout(time: 15, unit: 'MINUTES') {
                        sh '''
                            TF_LOG=INFO terraform apply -auto-approve tfplan.out > terraform-apply.log 2>&1
                        '''
                    }
                }
            }
        }

        stage('Capture Terraform Outputs') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        def outputs = sh(script: 'terraform output -json', returnStdout: true).trim()
                        def parsed = readJSON text: outputs
                        env.VPC_ID = parsed.vpc_id.value
                        env.PRIVATE_SUBNET_IDS = parsed.private_subnet_ids.value.join(",")
                        env.PUBLIC_SUBNET_IDS = parsed.public_subnet_ids.value.join(",")
                        env.RDS_ENDPOINT = parsed.rds_endpoint.value
                        env.RDS_USERNAME = parsed.rds_username.value
                        env.RDS_PASSWORD = parsed.rds_password.value
                    }
                }
            }
        }

        stage('Build Backend AMI (Packer)') {
            steps {
                dir("${PKR_DIR}") {
                    sh '''
                        packer init .
                        packer validate packer.pkr.hcl
                        packer build -var "component=backend" packer.pkr.hcl | tee backend-packer.log
                    '''
                }
            }
        }

        stage('Extract Backend AMI ID') {
            steps {
                script {
                    def log = readFile("${PKR_DIR}/backend-packer.log")
                    def match = log =~ /AMI: (ami-[a-z0-9]+)/

                    if (match) {
                        env.BACKEND_AMI_ID = match[0][1]
                        echo "Backend AMI: ${env.BACKEND_AMI_ID}"
                    } else {
                        error("AMI ID not found in backend log.")
                    }
                }
            }
        }

        stage('Build Frontend AMI (Packer)') {
            steps {
                dir("${PKR_DIR}") {
                    sh '''
                        packer build -var "component=frontend" packer.pkr.hcl | tee frontend-packer.log
                    '''
                }
            }
        }

        stage('Extract Frontend AMI ID') {
            steps {
                script {
                    def log = readFile("${PKR_DIR}/frontend-packer.log")
                    def match = log =~ /AMI: (ami-[a-z0-9]+)/

                    if (match) {
                        env.FRONTEND_AMI_ID = match[0][1]
                        echo "Frontend AMI: ${env.FRONTEND_AMI_ID}"
                    } else {
                        error("AMI ID not found in frontend log.")
                    }
                }
            }
        }

        stage('Create Backend Infrastructure') {
            steps {
                sh """
                    aws ec2 create-launch-template --launch-template-name backend-template --version-description "backend" \
                        --launch-template-data '{"ImageId":"${BACKEND_AMI_ID}","KeyName":"project.pem","InstanceType":"t2.micro"}' \
                        --region ${AWS_REGION}
                    # TODO: Add Target Group, ALB, and ASG
                """
            }
        }

        stage('Create Frontend Infrastructure') {
            steps {
                sh """
                    aws ec2 create-launch-template --launch-template-name frontend-template --version-description "frontend" \
                        --launch-template-data '{"ImageId":"${FRONTEND_AMI_ID}","KeyName":"project.pem","InstanceType":"t2.micro"}' \
                        --region ${AWS_REGION}
                    # TODO: Add Target Group, ALB, and ASG
                """
            }
        }

        stage('Update Backend .env with RDS Info') {
            steps {
                sh """
                    echo "DB_HOST=${RDS_ENDPOINT}" > .env
                    echo "DB_USER=${RDS_USERNAME}" >> .env
                    echo "DB_PASS=${RDS_PASSWORD}" >> .env
                """
                // Optionally: Add logic to copy this to EC2 or use with Packer
            }
        }

        stage('Update Frontend config.js with Backend ALB URL') {
            steps {
                script {
                    def backendALB = "http://backend-alb.example.com" // Replace with actual value
                    sh "sed -i 's|REPLACE_BACKEND_URL|${backendALB}|' ${PKR_DIR}/app/client/src/pages/config.js"
                }
            }
        }

        stage('Map Frontend ALB to Route53') {
            steps {
                sh """
                    aws route53 change-resource-record-sets --hosted-zone-id harishpro.com \
                      --change-batch '{
                        "Changes": [{
                          "Action": "UPSERT",
                          "ResourceRecordSet": {
                            "Name": "frontend.example.com",
                            "Type": "A",
                            "AliasTarget": {
                              "HostedZoneId": "ALB_ZONE_ID",
                              "DNSName": "frontend-alb-123456.us-east-1.elb.amazonaws.com",
                              "EvaluateTargetHealth": false
                            }
                          }
                        }]
                      }'
                """
            }
        }
    }

    post {
        always {
            echo "Pipeline completed."
        }
    }
}


