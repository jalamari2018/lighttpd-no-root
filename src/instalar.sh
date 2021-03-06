#!/bin/bash
#@(#) Este script realiza o processo de instalação do Lighttpd sem acesso root
# Felipe Bastos Nunes - 21/Oct/2020
# Leia o arquivo LICENSE para detalhes sobre cópia e uso deste pacote.

# Checando com o usuário se deseja utilizar o pacote padrão ou baixar o mais recente.
echo "Olá, vou lhe ajudar a instalar o servidor HTTP Lighttpd sem precisar de senha de super-usuário num sistema Linux qualquer."
echo "É importante que você compreenda que é para uso apenas educacional. Não tente rodar projetos reais (produção) com ele, pois muitas bibliotecas de segurança podem estar desativadas para permitir a execução."
echo "Primeiro me informe, por favor, se seu computador é provido de internet. (sim/não)"
read internet
latest="lighttpd-1.4.55"
if [ $internet == "sim" ]
then
	echo "OK, vou baixar uma das últimas versões do Lighttpd (1.4.55 foi a última que testei), aguarde..."
	`wget https://download.lighttpd.net/lighttpd/releases-1.4.x/latest.txt`
	latest=`cat latest.txt`
	`wget https://download.lighttpd.net/lighttpd/releases-1.4.x/$latest.tar.gz`
	`wget https://download.lighttpd.net/lighttpd/releases-1.4.x/$latest.sha256sum`
	`sha256sum --check $latest.sha256sum --ignore-missing --status`
	`rm $latest.sha256sum`
    confere=$?
    if [ confere == 1 ]
    then
        echo "Não posso garantir a segurança do arquivo baixado."
        echo "Contate o desenvolvedor do script."
        exit
    else
        echo "Checksum [OK]"
        `mv $latest.tar.gz server.tar.gz`
    fi
	rm latest.txt
	echo "Terminei o download! Descompactando..."
else
	echo "OK, vou utilizar o que veio no pacote (1.4.55), aguarde..."
	`cp pack.tar.gz server.tar.gz`
fi
`tar -xzf server.tar.gz`
`mv $latest server-src`
echo "Entrando no diretório do código fonte... [$latest]"
cd server-src
echo "Configurando o make e executando"
mkdir ~/lighttpd
echo "1 - Diretório destino criado."
# As opções de "without" estão aí para contornar algumas limitações.
# Por exemplo, para instalar e rodar num datashow que rodava um linux bem limitado, precisava desativar também
# o pcre. Então, se ao tentar executar o script, você perceber que ele acusa que não tem uma biblioteca (ele
# mostra isso ao chegar no passo 2 e 3), basta procurar qual opção desativa o uso dessa biblioteca.
./configure --prefix=$HOME/lighttpd --with-openssl --without-bzip2 #--without-pcre
echo "2 - Make configurado."
make
echo "3 - Make preparado"
make install
cd ..
rm -rf server-src
rm server.tar.gz
echo "4 - Instalação concluída, aguarde configuração inicial do servidor..."
cd ~/lighttpd
echo "5 - Criando pastas de configuração e armazenamento dos arquivos web..."
mkdir etc www uploads logs deps
echo "6 - Criando arquivo de configuração"
touch etc/lighttpd.conf
mkdir www/cgi-bin
# Diretório raiz do servidor (onde estarão os sites)
printf 'server.document-root = "'>>etc/lighttpd.conf
printf $HOME>>etc/lighttpd.conf
echo '/lighttpd/www/"'>>etc/lighttpd.conf
# Log de erros do sistema
touch logs/erros.log
printf 'server.errorlog="'>>etc/lighttpd.conf
printf $HOME>>etc/lighttpd.conf
echo '/lighttpd/logs/erros.log"'>>etc/lighttpd.conf
# PID para facilitar os scripts úteis
touch lighttpd.pid
printf 'server.pid-file="'>>etc/lighttpd.conf
printf $HOME>>etc/lighttpd.conf
echo '/lighttpd/lighttpd.pid"'>>etc/lighttpd.conf
# Diretório destino dos uploads
printf 'server.upload-dirs = ( "'>>etc/lighttpd.conf
printf $HOME>>etc/lighttpd.conf
echo '/lighttpd/uploads" )
server.port = 3000
server.modules = (
    "mod_access",
    "mod_alias",
    "mod_compress",
    "mod_redirect",
    "mod_fastcgi",
    "mod_setenv",
    "mod_status"
)
mimetype.assign = (
    ".html" => "text/html",
    ".txt" => "text/plain",
    ".jpg" => "image/jpeg",
    ".png" => "image/png",
    ".css" => "text/css"
)
index-file.names = ("index.html")
'>>etc/lighttpd.conf

# Criando scripts úteis na raiz da instalação.
echo "7 - Criando scripts úteis."
touch init.sh
echo '#!/bin/bash
echo "Iniciando o lighttpd"
`./sbin/lighttpd -Df etc/lighttpd.conf&`
'>>init.sh
`chmod +x init.sh`

touch uninstall.sh
echo '#!/bin/bash
cd ..
rm -rf lighttpd
'>>uninstall.sh
`chmod +x uninstall.sh`

touch stop.sh
echo '#!/bin/bash
echo "Parando o lighttpd"
cat lighttpd.pid | xargs kill
'>>stop.sh
`chmod +x stop.sh`

touch restart.sh
echo '#!/bin/bash
./stop.sh
./init.sh
'>>restart.sh
`chmod +x restart.sh`

echo "Muito bem, agora vou iniciar o servidor, faça bom proveito!"
echo "Lembre-se que o servidor está rodando em http://localhost:3000"
echo "Para iniciar, reiniciar ou parar o servidor, utilize os scripts criados na raiz da instalação."
cd ~/lighttpd
./init.sh
