# -DesafioDevops
O script Terraform deve criar uma máquina virtual na Azure, instalar o Docker na VM, subir um Container com WordPress e Automatização Completa.

Instruções detalhadas sobre como executar o código.

- Instalar o Terraform.
- Instalar o Azure CLI (para conectar-se a conta Azure)
- Criar uma pasta e colocar o aplicativo terraform e o arquivo main.tf desse repositório.

Todos os comandos necessários em ordem (pelo Prompt de Comando):

cd <caminho para pasta onde está os arquivos Terraform e main.tf>

az login para conectar-se a Azure

terraform init para preparar o projeto e baixar as ferramentas necessárias.

terraform plan para ver as alterações que o terraform planeja fazer na infraestrutura.

terraform apply para aplicar (fazer as mudanças de fato na infraestrutura. Confirmar com: yes)
- quando o apply estiver completo, ao final vai mostrar informações do banco de dados e o IP píblico.

ssh adminuser@<ip púlico> para conectar-se à máquina virtual.

docker version para verificar se o Docker está instalado e funcionando corretamente.

docker ps para verificar se o container do WordPress está em execução.
- deve conter 2 containers 1 wordpress e 1 mysql.

No navegador colocar o IP público para acessar o WordPress.


