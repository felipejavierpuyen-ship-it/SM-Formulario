({
    getValues : function(component, event, helper){
        var action = component.get("c.getValues");
        var recordId = component.get("v.recordId");
        
        action.setParams({ recordId : recordId });
        action.setCallback(this, function(response) {
            component.set('v.showSpinner', false); 
            var state = response.getState();
            if (state === "SUCCESS")  {
                var dataReturn = response.getReturnValue();
                //component.find("nroDocbuc").set("v.value", dataReturn.Cedula_o_NIT__c);
                //component.find("tipoDocbuc").set("v.value", dataReturn.Tipo_de_Documento__c);
                component.set('v.nroDocbuc', dataReturn.Cedula_o_NIT__c);
                component.set('v.tipoDocbuc', dataReturn.Tipo_de_Documento__c);
                
                if(dataReturn.Sistema_Existente__c == 'No Existe'){
                    component.set('v.openNewAcc', true);
                }
            }else{
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +  errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    
    findClienteBUC : function(component, event, helper) {
        var self = this;
        component.set('v.showSpinner', true);
        
        component.set('v.columnsValue', [
            {label: 'IdPersona', fieldName: 'idPersona', type: 'text'},
            {label: 'CodTipoDocumento', fieldName: 'codTipoDocumento', type: 'text'},
            {label: 'NumDocumento', fieldName: 'numDocumento', type: 'text'},
            
            {label: 'numDigitoVerificacion', fieldName: 'numDigitoVerificacion', type: 'text'},
            {label: 'codEstadoDocumento', fieldName: 'codEstadoDocumento', type: 'text'},
            {label: 'codTipoPersona', fieldName: 'codTipoPersona', type: 'text'},
            {label: 'nomPersona', fieldName: 'nomPersona', type: 'text'},
            {label: 'primerApellido', fieldName: 'primerApellido', type: 'text'},
            {label: 'segundoApellido', fieldName: 'segundoApellido', type: 'text'}
            /*{label: 'nombreCompleto', fieldName: 'nombreCompleto', type: 'text'},
            {label: 'codPersonaTipoIva', fieldName: 'codPersonaTipoIva', type: 'text'},
            {label: 'codCiiu', fieldName: 'codCiiu', type: 'text'},
            {label: 'fechaAlta', fieldName: 'fechaAlta', type: 'text'},
            {label: 'fechaBaja', fieldName: 'fechaBaja', type: 'text'},
            {label: 'codMotivoBaja', fieldName: 'codMotivoBaja', type: 'text'},
            {label: 'codGenero', fieldName: 'codGenero', type: 'text'},
            {label: 'codEstadoCivil', fieldName: 'codEstadoCivil', type: 'text'},
            {label: 'fechaNacimiento', fieldName: 'fechaNacimiento', type: 'text'},
            {label: 'codPaisNacimiento', fieldName: 'codPaisNacimiento', type: 'text'},
            {label: 'ciudadNacimiento', fieldName: 'ciudadNacimiento', type: 'text'},
            {label: 'fechaExpedicionDoc', fieldName: 'fechaExpedicionDoc', type: 'text'},
            {label: 'codTipoEmpresa', fieldName: 'codTipoEmpresa', type: 'text'},
            {label: 'empresa', fieldName: 'empresa', type: 'text'},
            {label: 'cargo', fieldName: 'cargo', type: 'text'},
            {label: 'esEntidadOficial', fieldName: 'esEntidadOficial', type: 'text'},
            {label: 'fechaModificacion', fieldName: 'fechaModificacion', type: 'text'}*/
            
        ]);
        var recordId = component.get("v.recordId");
        console.log("recordId: "+recordId);

        var action = component.get("c.consultarClienteBUC");
        action.setParams({ recordId : recordId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS")  {
                var dataReturn = response.getReturnValue();
                if (dataReturn != null && dataReturn !== undefined && dataReturn.output != null) {
                    if(dataReturn.output.success){
                        component.set('v.dataValue', dataReturn.output.data.value);
                    }
                }
                $A.get('e.force:refreshView').fire();
                console.log("dataReturn"+dataReturn);
            }else{
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +  errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
            component.set('v.showSpinner', false); 
            self.getValues(component, event, helper);
        });
        $A.enqueueAction(action);
    }
})