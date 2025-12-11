pipeline {
    agent any

    parameters {
        booleanParam(name: 'PLAN_TERRAFORM', defaultValue: true, description: 'Run terraform plan to preview infrastructure changes')
        booleanParam(name: 'APPLY_TERRAFORM', defaultValue: true, description: 'Apply infrastructure changes using terraform apply (VM, LB, networking)')
        booleanParam(name: 'DEPLOY_ANSIBLE', defaultValue: true, description: 'Run Ansible to deploy Gitea application on Azure VM')
        booleanParam(name: 'DESTROY_TERRAFORM', defaultValue: false, description: '⚠️ DANGER: Destroy infrastructure using terraform destroy')
        choice(name: 'DEPLOYMENT_MODE', choices: ['FAILOVER', 'FULL_STACK'], description: 'FAILOVER: Deploy only app infra (DB already exists). FULL_STACK: Deploy everything including database.')
    }

    environment {
        // Ansible repository configuration
        ANSIBLE_DIR       = 'ansible-az-demoGitea'
        ANSIBLE_BRANCH    = 'main'
        INVENTORY_FILE    = "${ANSIBLE_DIR}/inventory.ini"
        PLAYBOOK_FILE     = "${ANSIBLE_DIR}/playbook.yml"
        
        // Terraform configuration
        TF_DIR            = 'infra'
        TF_BRANCH         = 'main'
        
        // Notification
        DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1437993582756888648/wG9NzvbVm2zkXK6BYNItaS38CcpGo5tZrV8idq5Gk3aKQReQOyMa44mavFY23oqQJFyj"
    }

    stages {

        stage('Preparation') {
            steps {
                script {
                    echo "═══════════════════════════════════════════════════"
                    echo "🚀 Azure Gitea Deployment Pipeline"
                    echo "═══════════════════════════════════════════════════"
                    echo "Mode: ${params.DEPLOYMENT_MODE}"
                    echo "Plan: ${params.PLAN_TERRAFORM}"
                    echo "Apply: ${params.APPLY_TERRAFORM}"
                    echo "Ansible: ${params.DEPLOY_ANSIBLE}"
                    echo "═══════════════════════════════════════════════════"
                    
                    if (params.DEPLOYMENT_MODE == 'FAILOVER') {
                        echo "⚠️  FAILOVER MODE: Assumes MySQL database already exists and is replicating from AWS"
                        echo "    This will deploy: VM, Load Balancer, and Gitea application"
                    } else {
                        echo "📦 FULL_STACK MODE: Will deploy complete infrastructure including database"
                    }
                }
            }
        }

        stage('Clone Repositories') {
            steps {
                echo '🔄 Cleaning workspace and cloning repositories...'
                deleteDir()

                script {
                    // 1. Clone Terraform Repository (this repo)
                    echo "📥 Cloning Terraform Azure repository..."
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "${TF_BRANCH}"]],
                        userRemoteConfigs: [[url: 'https://github.com/andreaendigital/tf-az-infra-demoGitea']]
                    ])

                    // 2. Clone Ansible Repository
                    echo "📥 Cloning Ansible Azure repository..."
                    dir("${ANSIBLE_DIR}") {
                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: "${ANSIBLE_BRANCH}"]],
                            userRemoteConfigs: [[url: 'https://github.com/andreaendigital/ansible-az-demoGitea']]
                        ])
                    }
                    
                    echo "✅ Repositories cloned successfully"
                }
            }
        }

        stage('Verify Azure Credentials') {
            steps {
                echo '🔐 Verifying Azure credentials...'
                withCredentials([
                    azureServicePrincipal(
                        credentialsId: 'azure-service-principal',
                        subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                        clientIdVariable: 'ARM_CLIENT_ID',
                        clientSecretVariable: 'ARM_CLIENT_SECRET',
                        tenantIdVariable: 'ARM_TENANT_ID'
                    )
                ]) {
                    sh '''
                        echo "Azure credentials loaded"
                        echo "Subscription ID: ${ARM_SUBSCRIPTION_ID:0:8}..."
                    '''
                }
                echo '✅ Azure credentials verified'
            }
        }

        stage('Terraform Init') {
            steps {
                echo '⚙️  Initializing Terraform...'
                withCredentials([
                    azureServicePrincipal(
                        credentialsId: 'azure-service-principal',
                        subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                        clientIdVariable: 'ARM_CLIENT_ID',
                        clientSecretVariable: 'ARM_CLIENT_SECRET',
                        tenantIdVariable: 'ARM_TENANT_ID'
                    ),
                    string(credentialsId: 'mysql-admin-password', variable: 'TF_VAR_mysql_admin_password'),
                    string(credentialsId: 'azure-ssh-public-key', variable: 'TF_VAR_ssh_public_key')
                ]) {
                    dir("${TF_DIR}") {
                        sh '''
                            terraform init -upgrade
                            terraform --version
                        '''
                    }
                }
                echo '✅ Terraform initialized'
            }
        }

        stage('Terraform Plan') {
            when {
                expression { return params.PLAN_TERRAFORM }
            }
            steps {
                echo '📋 Planning Terraform changes...'
                withCredentials([
                    azureServicePrincipal(
                        credentialsId: 'azure-service-principal',
                        subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                        clientIdVariable: 'ARM_CLIENT_ID',
                        clientSecretVariable: 'ARM_CLIENT_SECRET',
                        tenantIdVariable: 'ARM_TENANT_ID'
                    ),
                    string(credentialsId: 'mysql-admin-password', variable: 'TF_VAR_mysql_admin_password'),
                    string(credentialsId: 'azure-ssh-public-key', variable: 'TF_VAR_ssh_public_key')
                ]) {
                    dir("${TF_DIR}") {
                        sh '''
                            terraform plan -out=tfplan
                        '''
                    }
                }
                echo '✅ Terraform plan completed - Review the changes above'
            }
        }

        stage('Terraform Apply') {
            when {
                expression { return params.APPLY_TERRAFORM }
            }
            steps {
                script {
                    echo '🚀 Applying Terraform changes...'
                    
                    if (params.DEPLOYMENT_MODE == 'FAILOVER') {
                        echo '⚠️  FAILOVER MODE: Deploying only VM and Load Balancer'
                        echo '   Database is assumed to already exist and be replicating'
                    }
                    
                    withCredentials([
                        azureServicePrincipal(
                            credentialsId: 'azure-service-principal',
                            subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                            clientIdVariable: 'ARM_CLIENT_ID',
                            clientSecretVariable: 'ARM_CLIENT_SECRET',
                            tenantIdVariable: 'ARM_TENANT_ID'
                        ),
                        string(credentialsId: 'mysql-admin-password', variable: 'TF_VAR_mysql_admin_password'),
                        string(credentialsId: 'azure-ssh-public-key', variable: 'TF_VAR_ssh_public_key')
                    ]) {
                        dir("${TF_DIR}") {
                            sh '''
                                terraform apply -auto-approve tfplan
                                
                                echo "════════════════════════════════════════"
                                echo "📊 TERRAFORM OUTPUTS"
                                echo "════════════════════════════════════════"
                                terraform output
                                echo "════════════════════════════════════════"
                            '''
                        }
                    }
                    echo '✅ Terraform apply completed successfully'
                }
            }
        }

        stage('Extract Terraform Outputs') {
            when {
                expression { return params.DEPLOY_ANSIBLE }
            }
            steps {
                echo '📤 Extracting Terraform outputs for Ansible...'
                withCredentials([
                    azureServicePrincipal(
                        credentialsId: 'azure-service-principal',
                        subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                        clientIdVariable: 'ARM_CLIENT_ID',
                        clientSecretVariable: 'ARM_CLIENT_SECRET',
                        tenantIdVariable: 'ARM_TENANT_ID'
                    )
                ]) {
                    dir("${TF_DIR}") {
                        script {
                            // Extract outputs and save to environment variables
                            env.VM_PUBLIC_IP = sh(
                                script: 'terraform output -raw vm_public_ip',
                                returnStdout: true
                            ).trim()
                            
                            env.MYSQL_HOST = sh(
                                script: 'terraform output -raw mysql_server_host',
                                returnStdout: true
                            ).trim()
                            
                            env.MYSQL_DBNAME = sh(
                                script: 'terraform output -raw mysql_database_name',
                                returnStdout: true
                            ).trim()
                            
                            env.MYSQL_USERNAME = sh(
                                script: 'terraform output -raw mysql_admin_username',
                                returnStdout: true
                            ).trim()
                            
                            echo "════════════════════════════════════════"
                            echo "📊 EXTRACTED VALUES FOR ANSIBLE"
                            echo "════════════════════════════════════════"
                            echo "VM Public IP: ${env.VM_PUBLIC_IP}"
                            echo "MySQL Host: ${env.MYSQL_HOST}"
                            echo "MySQL DB: ${env.MYSQL_DBNAME}"
                            echo "MySQL User: ${env.MYSQL_USERNAME}"
                            echo "════════════════════════════════════════"
                        }
                    }
                }
                echo '✅ Terraform outputs extracted'
            }
        }

        stage('Configure Ansible Inventory') {
            when {
                expression { return params.DEPLOY_ANSIBLE }
            }
            steps {
                echo '📝 Configuring Ansible inventory with Terraform outputs...'
                withCredentials([
                    string(credentialsId: 'mysql-admin-password', variable: 'MYSQL_PASSWORD')
                ]) {
                    script {
                        // Generate inventory.ini dynamically with Terraform outputs
                        def inventoryContent = """# Ansible Inventory for Azure Gitea
# Auto-generated by Jenkins Pipeline
# Generated: ${new Date()}

[gitea]
vm-gitea-azure ansible_host=${env.VM_PUBLIC_IP} ansible_user=azureuser ansible_ssh_private_key_file=~/.ssh/azure-gitea-key.pem

[gitea:vars]
# MySQL connection details (from Terraform outputs)
mysql_host=${env.MYSQL_HOST}
mysql_username=${env.MYSQL_USERNAME}
mysql_password=${MYSQL_PASSWORD}
mysql_dbname=${env.MYSQL_DBNAME}
"""
                        
                        writeFile file: "${INVENTORY_FILE}", text: inventoryContent
                        
                        echo "✅ Inventory file created at: ${INVENTORY_FILE}"
                        echo "Content:"
                        sh "cat ${INVENTORY_FILE}"
                    }
                }
            }
        }

        stage('Wait for VM to be Ready') {
            when {
                expression { return params.DEPLOY_ANSIBLE }
            }
            steps {
                echo '⏳ Waiting for Azure VM to be fully ready...'
                script {
                    retry(5) {
                        sleep(time: 30, unit: 'SECONDS')
                        sshagent(credentials: ['azure-ssh-key']) {
                            sh """
                                ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                                    azureuser@${env.VM_PUBLIC_IP} 'echo "VM is ready"'
                            """
                        }
                    }
                }
                echo '✅ VM is ready and accessible'
            }
        }

        stage('Run Ansible Playbook') {
            when {
                expression { return params.DEPLOY_ANSIBLE }
            }
            steps {
                echo '🎭 Running Ansible playbook to deploy Gitea...'
                sshagent(credentials: ['azure-ssh-key']) {
                    sh """
                        cd ${ANSIBLE_DIR}
                        
                        # Run Ansible playbook
                        ansible-playbook -i ${WORKSPACE}/${INVENTORY_FILE} ${PLAYBOOK_FILE} \
                            --extra-vars 'ansible_ssh_common_args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"' \
                            -v
                    """
                }
                echo '✅ Ansible deployment completed'
            }
        }

        stage('Verify Gitea Deployment') {
            when {
                expression { return params.DEPLOY_ANSIBLE }
            }
            steps {
                echo '🔍 Verifying Gitea is running...'
                script {
                    sleep(time: 10, unit: 'SECONDS')
                    
                    def giteaUrl = "http://${env.VM_PUBLIC_IP}:3000"
                    def maxRetries = 10
                    def retryDelay = 10
                    
                    for (int i = 1; i <= maxRetries; i++) {
                        try {
                            sh "curl -f -s -o /dev/null -w '%{http_code}' ${giteaUrl}"
                            echo "✅ Gitea is accessible at ${giteaUrl}"
                            env.GITEA_URL = giteaUrl
                            break
                        } catch (Exception e) {
                            if (i == maxRetries) {
                                error("❌ Gitea is not responding after ${maxRetries} retries")
                            }
                            echo "⏳ Attempt ${i}/${maxRetries}: Gitea not ready yet, waiting ${retryDelay}s..."
                            sleep(time: retryDelay, unit: 'SECONDS')
                        }
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { return params.DESTROY_TERRAFORM }
            }
            steps {
                script {
                    echo '⚠️  WARNING: Destroying infrastructure...'
                    
                    // Confirmation timeout
                    timeout(time: 5, unit: 'MINUTES') {
                        input message: 'Are you sure you want to DESTROY all infrastructure?',
                              ok: 'Yes, destroy everything'
                    }
                    
                    withCredentials([
                        azureServicePrincipal(
                            credentialsId: 'azure-service-principal',
                            subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                            clientIdVariable: 'ARM_CLIENT_ID',
                            clientSecretVariable: 'ARM_CLIENT_SECRET',
                            tenantIdVariable: 'ARM_TENANT_ID'
                        ),
                        string(credentialsId: 'mysql-admin-password', variable: 'TF_VAR_mysql_admin_password'),
                        string(credentialsId: 'azure-ssh-public-key', variable: 'TF_VAR_ssh_public_key')
                    ]) {
                        dir("${TF_DIR}") {
                            sh 'terraform destroy -auto-approve'
                        }
                    }
                    echo '✅ Infrastructure destroyed'
                }
            }
        }
    }

    post {
        success {
            script {
                echo '═══════════════════════════════════════════════════'
                echo '✅ DEPLOYMENT COMPLETED SUCCESSFULLY'
                echo '═══════════════════════════════════════════════════'
                
                if (params.DEPLOY_ANSIBLE && env.GITEA_URL) {
                    echo "🌐 Gitea URL: ${env.GITEA_URL}"
                    echo "📊 Access Gitea and complete initial setup"
                    
                    if (params.DEPLOYMENT_MODE == 'FAILOVER') {
                        echo ""
                        echo "🚨 FAILOVER MODE: Remember to:"
                        echo "   1. Stop replication on Azure MySQL: STOP SLAVE;"
                        echo "   2. Promote to standalone: RESET SLAVE ALL;"
                        echo "   3. Verify data is current"
                        echo "   4. Update DNS to point to Azure"
                    }
                }
                
                echo '═══════════════════════════════════════════════════'

                // Discord Notification
                sh """
                    MESSAGE="✅ **Azure Gitea Deployment Successful**\\n"
                    MESSAGE="\${MESSAGE}Pipeline: **${JOB_NAME}** #${BUILD_NUMBER}\\n"
                    MESSAGE="\${MESSAGE}Mode: **${params.DEPLOYMENT_MODE}**\\n"
                    
                    if [ -n "${env.GITEA_URL}" ]; then
                        MESSAGE="\${MESSAGE}Gitea URL: ${env.GITEA_URL}\\n"
                    fi
                    
                    curl -X POST ${DISCORD_WEBHOOK_URL} \
                         -H 'Content-Type: application/json' \
                         -d "{\\"username\\": \\"Jenkins Bot - Azure\\", \\"content\\": \\"\${MESSAGE}\\", \\"embeds\\": [ { \\"description\\": \\"[View Build](${BUILD_URL})\\", \\"color\\": 65280 } ]}"
                """
            }
        }

        failure {
            script {
                echo '═══════════════════════════════════════════════════'
                echo '❌ DEPLOYMENT FAILED'
                echo '═══════════════════════════════════════════════════'
                echo 'Check logs above for details'
                echo 'Terraform state may need manual intervention'
                echo '═══════════════════════════════════════════════════'

                // Discord Notification
                sh """
                    MESSAGE="❌ **Azure Gitea Deployment Failed**\\n"
                    MESSAGE="\${MESSAGE}Pipeline: **${JOB_NAME}** #${BUILD_NUMBER}\\n"
                    MESSAGE="\${MESSAGE}Mode: **${params.DEPLOYMENT_MODE}**"
                    
                    curl -X POST ${DISCORD_WEBHOOK_URL} \
                         -H 'Content-Type: application/json' \
                         -d "{\\"username\\": \\"Jenkins Bot - Azure\\", \\"content\\": \\"\${MESSAGE}\\", \\"embeds\\": [ { \\"description\\": \\"[View Failure](${BUILD_URL})\\", \\"color\\": 16711680 } ]}"
                """
            }
        }

        always {
            echo '🧹 Cleaning up...'
            cleanWs()
        }
    }
}
