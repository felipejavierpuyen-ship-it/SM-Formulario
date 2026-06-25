({
    doInit: function(component, event, helper) {
        //component.find("nroDocbuc").set("v.value", "1007312121");
        //component.find("tipoDocbuc").set("v.value", "1");
        //helper.getValues(component, event, helper);
        helper.findClienteBUC(component, event, helper);
    },
    
    handleConsultarBUC : function(component, event, helper) {
        var nroDocbuc = component.find("nroDocbuc").get("v.value");
        var tipoDocbuc = component.find("tipoDocbuc").get("v.value");
        console.log('nroDocbuc '+ nroDocbuc);
        console.log('tipoDocbuc'+ tipoDocbuc);
        if(nroDocbuc != '' && tipoDocbuc != ''){
            helper.findClienteBUC(component, event, helper);
        }else{
            component.find("notifLib").showToast({
                "variant": "error",
                "title": "Completa los campos para realizar la consulta. "
            });
        }
    },
    crearPersonAccount : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var allValidPersonAccount = component.find('requiredAccount').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && !inputCmp.get('v.validity').valueMissing;
        }, true);
        if(allValidPersonAccount){
            component.set('v.showSpinner', true);
            var action = component.get("c.createPersonAccount");
            action.setParams({ recordId : recordId, 
                              recAccount: component.get("v.accountPerson") });
            action.setCallback(this, function(response) {
                component.set('v.showSpinner', false); 
                component.set('v.openNewAcc', false);
                $A.get('e.force:refreshView').fire();                
            });
            $A.enqueueAction(action);
        }
    },
    crearEmpresaAccount : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var allValidPersonAccount = component.find('requiredAccount').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && !inputCmp.get('v.validity').valueMissing;
        }, true);
        if(allValidPersonAccount){
            component.set('v.showSpinner', true);
            
            var action = component.get("c.createEmpresaAccount");
            action.setParams({ recordId : recordId, 
                              recAccount: component.get("v.accountEmpresa") });
            action.setCallback(this, function(response) {
                component.set('v.showSpinner', false); 
                component.set('v.openNewAcc', false);
                $A.get('e.force:refreshView').fire();                
            });
            $A.enqueueAction(action);
        }
    }
})