pipeline {
  agent any
    stages {
        stage ('Build') {
            steps {
                sh '''#!/bin/bash
                python3.9 -m venv venv
                source venv/bin/activate
                pip install pip --upgrade
                pip install -r requirements.txt
                pip install gunicorn pymysql cryptography 
                export FLASK_APP=microblog.py
                flask translate compile
                flask db upgrade
                '''
            }
        }
        stage ('Test') {
            steps {
                sh '''#!/bin/bash
                source venv/bin/activate
                export PYTHONPATH=$(pwd)
                py.test ./tests/unit/ --verbose --junit-xml test-reports/results.xml
                '''
            }
            post {
                always {
                    junit 'test-reports/results.xml'
                }
            }
        }
        stage('OWASP FS SCAN') {
            steps {
                // Use the withCredentials step to inject the NVD API key into the environment
                withCredentials([string(credentialsId: 'NVD_API_KEY', variable: 'NVD_API_KEY')]) {
                    dependencyCheck additionalArguments: "--scan ./ --disableYarnAudit --disableNodeAudit --nvdApiKey ${NVD_API_KEY}", 
                                   odcInstallation: 'DP-Check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
      stage ('Deploy') {
            steps {
               script {
                    // Variables for script paths and EC2 instance details
                    def jenkinsServerKey = '/home/ubuntu/.ssh/id_ed25519'
                    def webServerIP = '10.0.4.179'
                    def setupScriptPath = '/var/lib/jenkins/workspace/workload_4_main/setup.sh'
                    def startupScriptPath = '/var/lib/jenkins/workspace/workload_4_main/start_app.sh'

                    // Step 1: Secure copy setup.sh to web_server EC2 instance
                    def setupCopyStatus = sh(script: """
                        scp -i ${jenkinsServerKey} -o StrictHostKeyChecking=no ${setupScriptPath} ubuntu@${webServerIP}:/home/ubuntu/scripts/setup.sh
                    """, returnStatus: true)

                    if (setupCopyStatus == 0) {
                        echo "setup.sh copied successfully."
                    } else {
                        error "Failed to copy setup.sh."
                    }

                    // Step 2: Secure copy start_app.sh to web_server EC2 instance
                    def startupCopyStatus = sh(script: """
                        scp -i ${jenkinsServerKey} -o StrictHostKeyChecking=no ${startupScriptPath} ubuntu@${webServerIP}:/home/ubuntu/scripts/start_app.sh
                    """, returnStatus: true)

                    if (startupCopyStatus == 0) {
                        echo "start_app.sh copied successfully."
                    } else {
                        error "Failed to copy start_app.sh."
                    }

                    // Step 3: Run the setup.sh script using source
                    sh """
                        ssh -i ${jenkinsServerKey} -o StrictHostKeyChecking=no ubuntu@${webServerIP} '
                            source /home/ubuntu/scripts/setup.sh
                        '
                    """
                }
            }
        }
    }
}
