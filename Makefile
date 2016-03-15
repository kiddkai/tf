
deploy:
	make -c ./amis
	@terraform plan
	@terraform apply
	
