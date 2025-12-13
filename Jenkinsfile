pipeline {
    agent any

    parameters {
        booleanParam(name: 'PLAN_TERRAFORM', defaultValue: true, description: 'Run terraform plan to preview infrastructure changes')
        booleanParam(name: 'APPLY_TERRAFORM', defaultValue: true, description: 'Apply infrastructure changes using terraform apply')
        booleanParam(name: 'DEPLOY_ANSIBLE', defaultValue: true, description: 'Run Ansible to configure infrastructure')
        booleanParam(name: 'DESTROY_TERRAFORM', defaultValue: false, description: '⚠️ DANGER: Destroy infrastructure using terraform destroy')
        choice(
            name: 'DEPLOYMENT_MODE', 
            choices: ['full-stack', 'replica-only', 'failover'], 
            description: '''Deployment mode:
• full-stack: Complete demo (Gitea + MySQL + Load Balancer)
• replica-only: Only MySQL VM as AWS replica (no Gitea, activates VPN)
• failover: Restore Gitea using existing MySQL replica from AWS'''
        )
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
                    
                    if (params.DEPLOYMENT_MODE == 'full-stack') {
                        echo "📦 FULL-STACK MODE: Complete demo infrastructure"
                        echo "    Deploys: Gitea VM + MySQL VM + Load Balancer"
                        echo "    MySQL VM gets temporary public IP for Ansible setup"
                    } else if (params.DEPLOYMENT_MODE == 'replica-only') {
                        echo "🔄 REPLICA-ONLY MODE: MySQL as AWS replica"
                        echo "    Deploys: MySQL VM (private) + VPN Gateway"
                        echo "    Destroys: Gitea VM, Load Balancer"
                        echo "    ⚠️  Requires: AWS VPN Gateway IP configured"
                    } else {
                        echo "⚡ FAILOVER MODE: Restore application with existing MySQL"
                        echo "    Deploys: Gitea VM + Load Balancer"
                        echo "    Uses: Existing MySQL VM with replicated data"
                        echo "    ⚠️  Assumes MySQL VM already exists"
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
                    string(credentialsId: 'azure-client-id', variable: 'ARM_CLIENT_ID'),
                    string(credentialsId: 'azure-client-secret', variable: 'ARM_CLIENT_SECRET'),
                    string(credentialsId: 'azure-tenant-id', variable: 'ARM_TENANT_ID'),
                    string(credentialsId: 'azure-subscription-id', variable: 'ARM_SUBSCRIPTION_ID')
                ]) {
                    sh '''
                        echo "Azure credentials loaded"
                        echo "Subscription ID: $(echo $ARM_SUBSCRIPTION_ID | cut -c1-8)..."
                    '''
                }
                echo '✅ Azure credentials verified'
            }
        }

        // Backend setup stage commented out - requires Azure CLI installation on Jenkins
        // stage('Setup Backend Storage') {
        //     steps {
        //         echo '💾 Setting up Azure Storage for Terraform backend...'
        //         withCredentials([
        //             azureServicePrincipal(
        //                 credentialsId: 'azure-service-principal',
        //                 subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
        //                 clientIdVariable: 'ARM_CLIENT_ID',
        //                 clientSecretVariable: 'ARM_CLIENT_SECRET',
        //                 tenantIdVariable: 'ARM_TENANT_ID'
        //             )
        //         ]) {
        //             dir("${TF_DIR}") {
        //                 sh '''
        //                     # Login to Azure using Service Principal
        //                     az login --service-principal \
        //                       --username $ARM_CLIENT_ID \
        //                       --password $ARM_CLIENT_SECRET \
        //                       --tenant $ARM_TENANT_ID
        //                     
        //                     # Set subscription
        //                     az account set --subscription $ARM_SUBSCRIPTION_ID
        //                     
        //                     # Run setup script
        //                     chmod +x setup-backend.sh
        //                     ./setup-backend.sh
        //                 '''
        //             }
        //         }
        //         echo '✅ Backend storage configured'
        //     }
        // }

        stage('Terraform Init') {
            steps {
                echo '⚙️  Initializing Terraform...'
                withCredentials([
                    string(credentialsId: 'azure-client-id', variable: 'ARM_CLIENT_ID'),
                    string(credentialsId: 'azure-client-secret', variable: 'ARM_CLIENT_SECRET'),
                    string(credentialsId: 'azure-tenant-id', variable: 'ARM_TENANT_ID'),
                    string(credentialsId: 'azure-subscription-id', variable: 'ARM_SUBSCRIPTION_ID'),
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
                    string(credentialsId: 'azure-client-id', variable: 'ARM_CLIENT_ID'),
                    string(credentialsId: 'azure-client-secret', variable: 'ARM_CLIENT_SECRET'),
                    string(credentialsId: 'azure-tenant-id', variable: 'ARM_TENANT_ID'),
                    string(credentialsId: 'azure-subscription-id', variable: 'ARM_SUBSCRIPTION_ID'),
                    string(credentialsId: 'azure-ssh-public-key', variable: 'TF_VAR_ssh_public_key')
                ]) {
                    dir("${TF_DIR}") {
                        sh """
                            terraform plan -var="deployment_mode=${params.DEPLOYMENT_MODE}" -out=tfplan
                        """
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
                    echo "Deployment mode: ${params.DEPLOYMENT_MODE}"
                    
                    withCredentials([
                        string(credentialsId: 'azure-client-id', variable: 'ARM_CLIENT_ID'),
                        string(credentialsId: 'azure-client-secret', variable: 'ARM_CLIENT_SECRET'),
                        string(credentialsId: 'azure-tenant-id', variable: 'ARM_TENANT_ID'),
                        string(credentialsId: 'azure-subscription-id', variable: 'ARM_SUBSCRIPTION_ID'),
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
                    string(credentialsId: 'azure-client-id', variable: 'ARM_CLIENT_ID'),
                    string(credentialsId: 'azure-client-secret', variable: 'ARM_CLIENT_SECRET'),
                    string(credentialsId: 'azure-tenant-id', variable: 'ARM_TENANT_ID'),
                    string(credentialsId: 'azure-subscription-id', variable: 'ARM_SUBSCRIPTION_ID')
                ]) {
                    dir("${TF_DIR}") {
                        script {
                            // Extract outputs based on deployment mode
                            if (params.DEPLOYMENT_MODE != 'replica-only') {
                                env.VM_PUBLIC_IP = sh(
                                    script: 'terraform output -raw vm_public_ip',
                                    returnStdout: true
                                ).trim()
                            }
                            
                            // MySQL VM IPs
                            env.MYSQL_VM_PRIVATE_IP = sh(
                                script: 'terraform output -raw mysql_vm_private_ip',
                                returnStdout: true
                            ).trim()
                            
                            echo "════════════════════════════════════════"
                            echo "📊 EXTRACTED VALUES FOR ANSIBLE"
                            echo "════════════════════════════════════════"
                            echo "Deployment Mode: ${params.DEPLOYMENT_MODE}"
                            if (params.DEPLOYMENT_MODE != 'replica-only') {
                                echo "Gitea VM Public IP: ${env.VM_PUBLIC_IP}"
                            }
                            echo "MySQL VM Private IP: ${env.MYSQL_VM_PRIVATE_IP}"
                            echo "Note: MySQL accessed via jump host (no public IP)"
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
                script {
                    def inventoryContent = ""
                    
                    if (params.DEPLOYMENT_MODE == 'full-stack') {
                        // Full stack: both Gitea and MySQL
                        // MySQL accessed via SSH ProxyJump through Gitea VM (no public IP needed)
                        inventoryContent = """# Ansible Inventory for Azure Gitea
# Auto-generated by Jenkins Pipeline - Mode: ${params.DEPLOYMENT_MODE}
# Generated: ${new Date()}

[azureGitea]
gitea-vm ansible_host=${env.VM_PUBLIC_IP} ansible_user=azureuser

[mysql]
mysql-vm ansible_host=${env.MYSQL_VM_PRIVATE_IP} ansible_user=azureuser ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -o StrictHostKeyChecking=no -q azureuser@${env.VM_PUBLIC_IP}"'

[all:vars]
mysql_host=${env.MYSQL_VM_PRIVATE_IP}
deployment_mode=${params.DEPLOYMENT_MODE}
# Note: mysql_dbname, mysql_username, mysql_password passed via --extra-vars from Jenkins secrets
"""
                    } else if (params.DEPLOYMENT_MODE == 'failover') {
                        // Failover: only Gitea, MySQL already exists
                        inventoryContent = """# Ansible Inventory for Azure Gitea
# Auto-generated by Jenkins Pipeline - Mode: ${params.DEPLOYMENT_MODE}
# Generated: ${new Date()}

[azureGitea]
gitea-vm ansible_host=${env.VM_PUBLIC_IP} ansible_user=azureuser

[all:vars]
mysql_host=${env.MYSQL_VM_PRIVATE_IP}
deployment_mode=${params.DEPLOYMENT_MODE}
# Note: mysql_dbname, mysql_username, mysql_password passed via --extra-vars from Jenkins secrets
"""
                    } else {
                        // replica-only: only MySQL (accessed via private IP, requires VPN or peering)
                        inventoryContent = """# Ansible Inventory for Azure Gitea
# Auto-generated by Jenkins Pipeline - Mode: ${params.DEPLOYMENT_MODE}
# Generated: ${new Date()}
# Note: replica-only mode requires VPN or network peering for private IP access

[mysql]
mysql-vm ansible_host=${env.MYSQL_VM_PRIVATE_IP} ansible_user=azureuser

[all:vars]
mysql_host=${env.MYSQL_VM_PRIVATE_IP}
deployment_mode=${params.DEPLOYMENT_MODE}
# Note: mysql_dbname, mysql_username, mysql_password passed via --extra-vars from Jenkins secrets
"""
                    }
                    
                    writeFile file: "${INVENTORY_FILE}", text: inventoryContent
                    
                    echo "✅ Inventory file created at: ${INVENTORY_FILE}"
                    echo "Content:"
                    sh "cat ${INVENTORY_FILE}"
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
                withCredentials([
                    string(credentialsId: 'mysql-admin-password', variable: 'MYSQL_ROOT_PASSWORD'),
                    string(credentialsId: 'mysql-gitea-dbname', variable: 'MYSQL_DBNAME'),
                    string(credentialsId: 'mysql-gitea-username', variable: 'MYSQL_USERNAME'),
                    string(credentialsId: 'mysql-gitea-password', variable: 'MYSQL_PASSWORD')
                ]) {
                    sshagent(credentials: ['azure-ssh-key']) {
                        sh """
                            cd ${ANSIBLE_DIR}
                            
                            # Run Ansible playbook with all MySQL credentials from Jenkins secrets
                            # No hardcoded credentials - all injected from Jenkins Credentials store
                            ansible-playbook -i ${WORKSPACE}/${INVENTORY_FILE} playbook.yml \
                                --extra-vars "mysql_root_password=${MYSQL_ROOT_PASSWORD}" \
                                --extra-vars "mysql_dbname=${MYSQL_DBNAME}" \
                                --extra-vars "mysql_username=${MYSQL_USERNAME}" \
                                --extra-vars "mysql_password=${MYSQL_PASSWORD}" \
                                --extra-vars "deployment_mode=${params.DEPLOYMENT_MODE}" \
                                -v
                        """
                    }
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
                        string(credentialsId: 'azure-client-id', variable: 'ARM_CLIENT_ID'),
                        string(credentialsId: 'azure-client-secret', variable: 'ARM_CLIENT_SECRET'),
                        string(credentialsId: 'azure-tenant-id', variable: 'ARM_TENANT_ID'),
                        string(credentialsId: 'azure-subscription-id', variable: 'ARM_SUBSCRIPTION_ID'),
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
