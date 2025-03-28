#!/bin/bash
# Usage: ./setup-ssh.sh <remote_host> <remote_user>

REMOTE_HOST=$1
REMOTE_USER=$2
SSH_KEY="$HOME/.ssh/ansible"

[ $# -ne 2 ] && { echo "Usage: $0 <host> <user>"; exit 1; }

# Generate SSH key pair if not existing
if [ ! -f "$SSH_KEY" ]; then
    ssh-keygen -q -t ed25519 -f "$SSH_KEY" -N ""
fi

# Get password interactively
read -s -p "Enter REMOTE password for $REMOTE_USER: " REMOTE_PASS
echo

# First connection: add key to user's authorized_keys
sshpass -p "$REMOTE_PASS" ssh-copy-id \
    -o StrictHostKeyChecking=no \
    -i "$SSH_KEY.pub" \
    "$REMOTE_USER@$REMOTE_HOST"

#Use SSH key with heredoc
ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" << EOF
    # Copy key to root with proper sudo
    echo "$REMOTE_PASS" | sudo -S mkdir -p /root/.ssh
    sudo cp ~/.ssh/authorized_keys /root/.ssh/
    sudo chmod 700 /root/.ssh
    sudo chmod 600 /root/.ssh/authorized_keys

    # Configure SSH securely
    sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
EOF

echo "Setup complete! Test with:"
echo "ssh -i $SSH_KEY $REMOTE_USER@$REMOTE_HOST"
echo "ssh -i $SSH_KEY root@$REMOTE_HOST"
