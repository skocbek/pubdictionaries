echo "     ##### Local - valid id/password #####     "
ruby ./test.terms_to_idlists.01.rb "priancho@gmail.com" "password" "http://localhost:3000/dictionaries/EntrezGene%20-%20Homo%20Sapiens"
echo "     ##### Local - valid guest #####     "
ruby ./test.terms_to_idlists.01.rb "" "" "http://localhost:3000/dictionaries/EntrezGene%20-%20Homo%20Sapiens"
echo "     ##### Local - invalid email #####     "
ruby ./test.terms_to_idlists.01.rb "priancho@---gmail.com" "password" "http://localhost:3000/dictionaries/EntrezGene%20-%20Homo%20Sapiens"
echo "     ##### Local - invalid password#####     "
ruby ./test.terms_to_idlists.01.rb "priancho@gmail.com" "pass--word" "http://localhost:3000/dictionaries/EntrezGene%20-%20Homo%20Sapiens"
echo "     ##### Local - invalid uri #####     "
ruby ./test.terms_to_idlists.01.rb "priancho@gmail.com" "password" "http://localhost:3000/dictionaries"
