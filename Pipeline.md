pipeline {
  agent any

  environment {
    IMAGE_NAME = 'your-dockerhub-username/sales-dashboard'
    IMAGE_TAG = 'latest'
    AWS_REGION = 'us-east-1'
    EKS_CLUSTER_NAME = 'your-eks-cluster-name'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
          script {
            docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-token') {
              docker.image("${IMAGE_NAME}:${IMAGE_TAG}").push()
            }
          }
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        withAWS(region: "${AWS_REGION}", credentials: 'aws-eks-creds') {
          script {
            sh """
              aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
              kubectl apply -f k8s/deployment.yaml
            """
          }
        }
      }
    }
  }
}
