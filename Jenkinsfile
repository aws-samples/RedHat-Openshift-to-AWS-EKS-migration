pipeline {
    agent any
    parameters {
        string(name: 'SRC_GIT_REPO', defaultValue: '', description: 'Source Openshift Git Repository')
        string(name: 'SRC_GIT_BRANCH', defaultValue: 'main', description: 'Source Openshift Git Branch')
        string(name: 'DEST_GIT_REPO', defaultValue: '', description: 'Source Openshift Git Repository')
        string(name: 'DEST_GIT_BRANCH', defaultValue: 'main', description: 'Source Openshift Git Repository Branch')
        string(name: 'HELM_TEMPLATE_REPO', defaultValue: '', description: 'Helm Template Repository')
        string(name: 'HELM_TEMPLATE_BRANCH', defaultValue: 'main', description: 'Helm Template Repository Branch')    
        choice(name: 'DEPLOY_MODE', choices: ['Install', 'Destroy', 'View'], description: 'Select Deployment action you need to perform in Cluster')
        string(name: 'CLUSTER_NAME', defaultValue: '', description: 'Provide EKS CLuster Name')
        string(name: 'REGION', defaultValue: '', description: 'AWS EKS cluster region Where to Deploy')
        string(name: 'NAMESPACE', defaultValue: '', description: 'Deployment Namespace')       
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
        stage('OpenShift to EKS File Migration') {
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
        stage('SAST Scanning') {
            steps {
                dir("DEST_REPO") {
                    print "############## Add Steps for SAST scanning of Target Files #####################"
                }
            }
        }
        stage('Connect to DEV Cluster') {
            steps {
                dir("DEST_REPO") {
                    withAWS(credentials: 'AWS_CREDENTIAL' , region: params.REGION) {
                            sh "aws eks update-kubeconfig --region ${params.REGION} --name ${params.CLUSTER_NAME}"
                           
                    }
                }
            }
        }
        
        stage('Deploy to EKS CLuster') {
            steps {
                script {
                withAWS(credentials: 'AWS_CREDENTIAL' , region: params.REGION) {
                dir("DEST_REPO") {
                     if (params.DEPLOY_MODE == 'Destroy') {
                        sh '''
                            for dir in */; do
                                if [ -d "$dir" ]; then
                                    helm_dir="${dir%/}"
                                    helm uninstall $helm_dir -n $DEV_NAMESPACE
                                fi
                            done
                       '''
                       print "############## DEV  uninstall Sucessful #####################"
                     } else if(params.DEPLOY_MODE == 'Install') { 
                        sh '''
                            for dir in */; do
                                if [ -d "$dir" ]; then
                                    helm_dir="${dir%/}"
                                    helm install $helm_dir ./$helm_dir -n $DEV_NAMESPACE
                                fi

                            done
                       '''
                       print "############## DEV Deployment Sucessful #####################"
                       
                     } else {
                       sh '''
                            for dir in */; do
                                if [ -d "$dir" ]; then
                                    helm_dir="${dir%/}"
                                    helm template $helm_dir $helm_dir
                                fi
                            done
                       '''
                     
                     }
                     
                }
                }
                
                
            }
        }}
        stage('Run Unit Test Case') {
            steps {
              script {
                if(params.Deploy_Mode == 'Install') {
                     withAWS(credentials: env.AWS_CREDENTIAL , region: env.REGION) {
                            sh '''
                               sleep 15s
                               kubectl get sa -n $NAMESPACE
                               kubectl get pods -n $NAMESPACE
                               kubectl get svc -n $NAMESPACE
                            '''
                    }
                } else {
                        print "############## Skipped Unit Test  #####################"
                }  
                
                
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