pipeline {
    agent any
    parameters {
        string(name: 'SRC_GIT_REPO', defaultValue: '', description: 'Source Openshift Git Repository')
        string(name: 'SRC_GIT_BRANCH', defaultValue: 'main', description: 'Source Openshift Git Branch')
        string(name: 'DEST_GIT_REPO', defaultValue: '', description: 'Source Openshift Git Repository')
        string(name: 'DEST_GIT_BRANCH', defaultValue: 'main', description: 'Source Openshift Git Repository Branch')
        string(name: 'HELM_TEMPLATE_REPO', defaultValue: '', description: 'Helm Template Repository')
        string(name: 'HELM_TEMPLATE_BRANCH', defaultValue: 'main', description: 'Helm Template Repository Branch')    
        }

    stages {
        stage('Git CheckOut') {
            steps {
                dir("SRC_REPO") {
                     git branch: params.SRC_GIT_BRANCH, credentialsId: 'GIT_CREDENTIAL', url: params.SRC_GIT_REPO
                }
                dir("Operation") {
                     git branch: params.HELM_TEMPLATE_BRANCH, credentialsId: 'GIT_CREDENTIAL', url: params.HELM_TEMPLATE_REPO
                }
                dir("DEST_REPO") {
                     git branch: params.DEST_GIT_BRANCH, credentialsId: 'GIT_CREDENTIAL' , url: params.DEST_GIT_REPO
                }
                
                
            }
        }
        stage('Migration') {
            steps {
                sh "ls -la"
                sh "python3 convert_ose_to_eks.py"
                dir("DEST_REPO") {    
                    sh '''
                      echo -e "\n ${BUILD_NUMBER} : migration date $(date +'%Y-%m-%d %H:%M:%S')" >> README.md
                      pwd
                      ls -la
                      git add *
                      git commit -m "Migrated from jenkin"
                      git push --set-upstream origin main
                    '''
                }
            }
        }
        stage('Loading') {
            steps {
                dir("DEST_REPO") {    
                    sh '''
                      echo -e "\n ${BUILD_NUMBER} : migration date $(date +'%Y-%m-%d %H:%M:%S')" >> README.md
                      pwd
                      ls -la
                      git add *
                      git commit -m "Migrated from jenkin"
                      git push --set-upstream origin main
                    '''
                }
            }
        }
       
        stage('Clean Up') {
            steps {
                deleteDir()
            }
        }
    }
    post { 
        always { 
            cleanWs()
        }
       }
}
