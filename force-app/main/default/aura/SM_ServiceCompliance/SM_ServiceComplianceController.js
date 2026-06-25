({
    init : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        component.set('v.showSpinner', true);
        
        var action = component.get("c.consultarCompliance");
        action.setParams({recordId: recordId});
        action.setCallback(this, function(response) {
            component.set('v.showSpinner', false);
            $A.get('e.force:refreshView').fire();
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS")  {
                var dataReturn = response.getReturnValue();
                if (dataReturn != null && dataReturn !== undefined) {
                    if(dataReturn.Success){
                        component.set('v.dataValue', dataReturn);
                        //component.set('v.resultados', dataReturn.RiskCompliance.Resultados);
                    }else{
                        component.set('v.msgError', dataReturn.error);
                    }
                }
            }
            else {
                console.log("No success");
            }
        });
        $A.enqueueAction(action);
    }
})