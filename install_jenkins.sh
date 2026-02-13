#!/bin/bash

# Update system
sudo dnf update -y

# Install Java (required for Jenkins)
sudo dnf install -y java-21-openjdk java-21-openjdk-devel

# Verify Java
java -version

# Install required utilities
sudo dnf install -y wget unzip git

# Install Gradle (optional, remove if not needed)
GRADLE_VERSION=9.3.1
wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp
sudo mkdir -p /opt/gradle
sudo unzip -d /opt/gradle /tmp/gradle-${GRADLE_VERSION}-bin.zip
sudo ln -sfn /opt/gradle/gradle-${GRADLE_VERSION} /opt/gradle/latest

# Set Gradle environment
sudo tee /etc/profile.d/gradle.sh <<EOF
export GRADLE_HOME=/opt/gradle/latest
export PATH=\$PATH:\$GRADLE_HOME/bin
EOF
sudo chmod +x /etc/profile.d/gradle.sh
source /etc/profile.d/gradle.sh
gradle -v

# Remove expired Jenkins key if exists
sudo rpm -qa gpg-pubkey* | grep -i fcef32e7 && sudo rpm -e gpg-pubkey-fcef32e7-*

# Import correct Jenkins GPG key
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Add Jenkins repo
sudo tee /etc/yum.repos.d/jenkins.repo <<EOF
[jenkins]
name=Jenkins-stable
baseurl=https://pkg.jenkins.io/redhat-stable
gpgcheck=1
EOF

# Clean cache
sudo dnf clean all
sudo dnf makecache

# Install Jenkins
sudo dnf install -y jenkins

# Enable and start Jenkins service
sudo systemctl enable --now jenkins

# Open firewall port for Jenkins
sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp
sudo firewall-cmd --reload

# Show Jenkins initial admin password
echo "Your initial Jenkins admin password is:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

echo "Installation complete! Access Jenkins at http://<server-ip>:8080"
