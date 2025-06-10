pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-2'  // Change as per your region
        TF_DIR = 'terraform/terraform-infra'
        PKR_DIR = 'packer'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init & Apply (VPC + RDS)') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        terraform init
                        terraform apply -auto-approve
                    '''
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
                        --launch-template-data '{"ImageId":"${BACKEND_AMI_ID}", "key_name ":"project.pem", "InstanceType":"t2.micro"}' \
                        --region ${AWS_REGION}
                    
                    # TODO: Create Target Group, ALB, ASG for Backend using CLI or Terraform
                """
            }
        }

        stage('Create Frontend Infrastructure') {
            steps {
                sh """
                    aws ec2 create-launch-template --launch-template-name frontend-template --version-description "frontend" \
                        --launch-template-data '{"ImageId":"${FRONTEND_AMI_ID}", "key_name ":"project.pem", "InstanceType":"t2.micro"}' \
                        --region ${AWS_REGION}
                    
                    # TODO: Create Target Group, ALB, ASG for Frontend using CLI or Terraform
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
                // You can SCP this .env to a user-data script or AMI provision
            }
        }

        stage('Update Frontend config.js with Backend ALB URL') {
            steps {
                script {
                    def backendALB = "http://backend-alb.example.com" // Replace with actual ALB DNS
                    sh "sed -i 's|REPLACE_BACKEND_URL|${backendALB}|' ${PKR_DIR}/app/client/src/pages/config.js"
                }
            }
        }

        stage('Map Frontend ALB to Route53') {
            steps {
                sh """
                    aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID \
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

