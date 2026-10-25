pipeline {
    agent any

    environment {
        IMAGE_NAME      = 'rise-app'
        CONTAINER_NAME  = 'rise-app-container'
        PORT_MAPPING    = '5000:5000'
        // De fysieke map op je Debian-server waar het SQLite databasebestand veilig bewaard blijft
        HOST_DATA_DIR   = '/var/rise-data'
    }

    stages {
        stage('Verify Docker') {
            steps {
                echo 'Controleren of Docker operationeel is op het systeem...'
                sh 'docker --version'
            }
        }

        stage('Checkout') {
            steps {
                echo 'Broncode ophalen uit de Git repository...'
                checkout scm
            }
        }

        stage('Execute Tests') {
            steps {
                echo 'xUnit en bUnit testen uitvoeren binnen de container/agent...'
                // Voert alle tests in de test-projecten van Rise.sln uit en genereert een .trx rapport
                sh "dotnet test Rise.sln -c Release --logger:trx"
            }
            post {
                always {
                    // Publiceert de testresultaten visueel in de Jenkins-gebruikersinterface
                    mstest testResultsFile: '**/*.trx', keepLongStdio: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                echo "Starten van de multi-stage Docker build voor image: ${env.IMAGE_NAME}..."
                // Dit activeert de Dockerfile waarin de code wordt gecompileerd en gepubliceerd naar .NET 10
                sh "docker build -t ${env.IMAGE_NAME}:latest ."
            }
        }

        stage('Docker Deploy') {
            steps {
                echo 'Controleren en aanmaken van de host-datamap voor SQLite...'
                // UID 33 is de 'www-data' gebruiker binnen de .NET container. 
                // De map op de Debian-host moet deze rechten hebben om het .db bestand te kunnen schrijven.
                sh "sudo mkdir -p ${env.HOST_DATA_DIR}"
                sh "sudo chown -R 33:33 ${env.HOST_DATA_DIR}"
                sh "sudo chmod 775 ${env.HOST_DATA_DIR}"

                echo 'Bestaande actieve container stoppen en opschonen...'
                // Voorkomt dat de build faalt als de container de allereerste keer nog niet bestaat
                sh "docker stop ${env.CONTAINER_NAME} || true"
                sh "docker rm ${env.CONTAINER_NAME} || true"

                echo "Nieuwe container '${env.CONTAINER_NAME}' opstarten op poort ${env.PORT_MAPPING}..."
                // Start de applicatie met het gekoppelde SQLite-volume en automatische herstart-policy
                sh """
                    docker run -d \
                    --name ${env.CONTAINER_NAME} \
                    -p ${env.PORT_MAPPING} \
                    -v ${env.HOST_DATA_DIR}:/app/data \
                    --restart always \
                    ${env.IMAGE_NAME}:latest
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline succesvol voltooid! De applicatie draait in Docker op poort ${env.PORT_MAPPING}."
        }
        failure {
            echo 'De pipeline is afgebroken wegens een fout. Raadpleeg de console-output hierboven.'
        }
    }
}
