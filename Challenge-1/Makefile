
ENVNAME=dev
PROJECT=PROJECT
REGION=europe-west2

TFSTATE_BUCKET=$(PROJECT)_tfstate
TFSTATE_PREFIX=$(ENVNAME)
TFPARAMS_FILE=params/$(ENVNAME).tfvars
TFPLAN_FILE=/tmp/$(PROJECT)_$(ENVNAME)
TF_TOKEN=$$(gcloud auth print-access-token --project $(PROJECT))
TF_EXEC=TF_VAR_access_token=$(TF_TOKEN) terraform

all: plan

clean: prep
	@rm -rf .terraform

init: clean
	@$(TF_EXEC) init --upgrade \
		-backend-config="access_token=$(TF_TOKEN)"

plan: init
	@$(TF_EXEC) plan -refresh=true -out=$(TFPLAN_FILE) \
		-var-file=$(TFPARAMS_FILE) .

apply:
	@$(TF_EXEC) apply $(TFPLAN_FILE) && rm -f $(TFPLAN_FILE)

destroy: init
	@$(TF_EXEC) destroy -var-file=$(TFPARAMS_FILE)

target: init
	@$(TF_EXEC) plan -refresh=true -out=$(TFPLAN_FILE) \
		-var-file=$(TFPARAMS_FILE) \
		-target=$(TARGET)

state: init
	@$(TF_EXEC) state list

remove: init
	@$(TF_EXEC) state rm $(RESOURCE)

import: init
	@$(TF_EXEC) import -var-file=$(TFPARAMS_FILE) $(TARGET) $(RESOURCE)

refresh:
	@$(TF_EXEC) refresh -var-file=$(TFPARAMS_FILE)

