({
    // Sets an empApi error handler on component initialization
    onInit : function(component, event, helper) {
        // Get the empApi component
        const empApi = component.find('empApi');
        const userId = $A.get("$SObjectType.CurrentUser.Id");
        const recordId = component.get("v.recordId");
        console.log("Current Record ID:", recordId);

        component.set("v.userId", userId);
        console.log("Usuario logueado:", userId);


        // Uncomment below line to enable debug logging (optional)
        // empApi.setDebugFlag(true);
        helper.subscribe(component);

        // Register error listener and pass in the error handler function
        empApi.onError($A.getCallback(error => {
            // Error can be any type of error (subscribe, unsubscribe...)
            console.error('EMP API error: ', JSON.stringify(error));
        }));
    },

    

    handleCategoryChange: function(component, event, helper) {
        console.log('handleCategoryChange:')
        helper.refreshOmniScript(component);
    }
})