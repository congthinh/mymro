useradd rstudio
mkdir /home/rstudio
chown rstudio:rstudio /home/rstudio
passwd rstudio <<EOF
rstudio
rstudio
EOF
