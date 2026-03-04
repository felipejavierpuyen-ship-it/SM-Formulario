global with sharing class DMCustomFunctions implements Callable {

    /*
     * input  - arguments - List<Object> of arguments passed to the function
     * output - result    - The function supports single Object values, List<Object>,
     * or Map<String, Object>
     */
    private static final Integer COD_TEL_PRINCIPAL = 8;
    private static final Integer COD_EMAIL_PRINCIPAL = 10;
    private static final Map<String, String> PARTICIPANT_ROLE_MAP = new Map<String, String>{
        'Propietario' => 'ASEGURADO',
        'Deudor'      => 'AFIANZADO',
        'Inquilino'   => 'INQUILINO' };
	private static final Map<String, Integer> DOC_TYPE_MAP = new Map<String, Integer>{
        'Cédula de ciudadanía'            => 1,
        'NIT'                             => 3,
        'Cédula Extranjería'              => 2,
        'Tarjeta de identidad'            => 4,
        'Pasaporte'                       => 5,
        'Permiso Especial de Permanencia' => 13 };
    
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, input, output, options);
    }

    global Boolean invokeMethod(String methodName, Map<String, Object> inputs, Map<String, Object> output, Map<String, Object> options) {
        
        if (methodName == 'splitToObjectsFlexible') {
            List<Object> arguments = (List<Object>) inputs.get('arguments');
            output.put('result', splitToObjectsFlexible(arguments));
        }else if (methodName == 'getFormatParticipants') {
            List<Object> arguments = (List<Object>) inputs.get('arguments');
            output.put('result', getFormatParticipants(arguments));
        }
        
        return true;
    }
    
    // =========================================================
    // NUESTRO MÉTODO DEFINITIVO: splitToObjectsFlexible
    // =========================================================
    private List<Map<String, Object>> splitToObjectsFlexible(List<Object> arguments) {
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        
        // Validamos que vengan los 3 parámetros y el valor principal no sea nulo
        if (arguments != null && arguments.size() >= 3 && arguments[0] != null) {
            String inputStr = String.valueOf(arguments[0]);
            String separator = String.valueOf(arguments[1]);
            String keyName = String.valueOf(arguments[2]);
            
            // Separamos la cadena
            List<String> values = inputStr.split(separator);
            
            // Armamos la lista de objetos
            for (String val : values) {
                Map<String, Object> obj = new Map<String, Object>();
                obj.put(keyName, val.trim()); 
                resultList.add(obj);
            }
        }
        return resultList;
    }

    private List<Map<String, Object>> getFormatParticipants(List<Object> arguments) {
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();

        if(arguments != null && arguments.size() >= 1 && arguments[0] != null){
            String slipId = String.valueOf(arguments[0]);
            Slip__c slip = [
                SELECT Id, Name, Caso__c, Tipo_IVA__c
                FROM Slip__c 
                WHERE Id =: slipId LIMIT 1
            ];

            List<Participante_de_Poliza__c> lstPart = [
                SELECT Id, Cedula_o_NIT__c, Tipo_de_Documento__c, Tipo_de_Participante__c, Cliente__c, EsTomador__c, Cliente__r.SM_Direccion__c,
                Cliente__r.FirstName, Cliente__r.LastName, Cliente__r.Phone, Cliente__r.SM_CorreoElectronico__c, Cliente__r.SM_Ciudad__c,
                Cliente__r.SM_Ciudad__r.SFC_Codigo__c, Cliente__r.SM_Ciudad__r.SM_PoblacionPrincipal__c,
                Cliente__r.SM_Ciudad__r.SM_PoblacionPrincipal__r.SFC_Codigo__c, Cliente__r.SM_Ciudad__r.SM_PoblacionPrincipal__r.SM_PoblacionPrincipal__c,
                Cliente__r.SM_Ciudad__r.SM_PoblacionPrincipal__r.SM_PoblacionPrincipal__r.Codigo_poblacion__c
                FROM Participante_de_Poliza__c
                WHERE Caso_Relacionado__c =: slip.Caso__c
            ];

            if(lstPart.size() > 0){
                resultList = mapRoles(lstPart, slip);
            }
        }

         return resultList;
    }

    private List<Map<String, Object>> mapRoles(List<Participante_de_Poliza__c> lstPart, Slip__c slip){
        List<Map<String, Object>> rolesFinalList = new List<Map<String, Object>>();
        Boolean limiteTomadorAlcanzado = false;
        Integer afianzadoCounter = 0;
        
        for(Participante_de_Poliza__c ppRecord : lstPart) {
            if(ppRecord.Cliente__c != null){
                Map<String, Object> baseMap = formatPartPoliz(ppRecord, slip);
                if(baseMap.get('rol') == 'AFIANZADO') {
                    afianzadoCounter++;
                    baseMap.put('posicion', afianzadoCounter);
                }
                
                rolesFinalList.add(baseMap);
                
                if(ppRecord.EsTomador__c){
                    // EQUIVALENTE A 'ParticipanteArrendatario': SIN LIMIT, Todos con EsTomador__c = TRUE
                    Map<String, Object> arrendatarioMap = baseMap.clone(); 
                    arrendatarioMap.put('rol', 'ARRENDATARIO');
                    arrendatarioMap.remove('posicion');
                    rolesFinalList.add(arrendatarioMap);
                    
                    // EQUIVALENTE A 'ParticipanteTomador': CON LIMIT 1
                    // Solo se agrega una vez en todo el proceso
                    if(!limiteTomadorAlcanzado) {
                        Map<String, Object> tomadorMap = baseMap.clone();
                        tomadorMap.put('rol', 'TOMADOR');
                        tomadorMap.remove('posicion');
                        rolesFinalList.add(tomadorMap);
                        limiteTomadorAlcanzado = true; // Simula el LIMIT 1 del Data Mapper
                    }
                }
            }
        }
        return rolesFinalList;
    }

    public static Map<String, Object> formatPartPoliz(Participante_de_Poliza__c ppRecord, Slip__c slipRecord){
        Map<String, Object> roleMap = new Map<String, Object>();
        putIfNotNull(roleMap, 'nroDocumento', ppRecord.Cedula_o_NIT__c);
        putIfNotNull(roleMap, 'nombres', ppRecord.Cliente__r?.FirstName);
        putIfNotNull(roleMap, 'primerApellido', ppRecord.Cliente__r?.LastName);
        putIfNotNull(roleMap, 'codTipoIva', safeInteger(slipRecord.Tipo_IVA__c));
        
        putFromMap(roleMap, 'rol', ppRecord.Tipo_de_Participante__c, PARTICIPANT_ROLE_MAP);
        putFromMap(roleMap, 'codTipoDocumento', ppRecord.Tipo_de_Documento__c, DOC_TYPE_MAP);

        if(String.isNotBlank(ppRecord.Cliente__r?.Phone)){
            roleMap.put('telefonos', new List<Map<String, Object>>{
                new Map<String, Object>{
                    'telefono' => ppRecord.Cliente__r.Phone,
                    'codTipoTelefono' => COD_TEL_PRINCIPAL }
            });
        }
        
        if(String.isNotBlank(ppRecord.Cliente__r?.SM_CorreoElectronico__c)){
            roleMap.put('emails', new List<Map<String, Object>>{
                new Map<String, Object>{
                    'email' => ppRecord.Cliente__r.SM_CorreoElectronico__c,
                    'codTipoEmail' => COD_EMAIL_PRINCIPAL }
            });
        }
        
        if(ppRecord.Cliente__r != null) {
            Map<String, Object> addressMap = new Map<String, Object>();
            putIfNotNull(addressMap, 'direccion', ppRecord.Cliente__r.SM_Direccion__c);
            putIfNotNull(addressMap, 'codTipoDireccion', 1);
            putIfNotNull(addressMap, 'isDireccionPrincipal', true);
            putIfNotNull(addressMap, 'codMunicipio', safeInteger(ppRecord.Cliente__r.SM_Ciudad__r?.SFC_Codigo__c));
            putIfNotNull(addressMap, 'codDepartamento', safeInteger(ppRecord.Cliente__r.SM_Ciudad__r?.SM_PoblacionPrincipal__r?.SFC_Codigo__c));
            putIfNotNull(addressMap, 'codPais', safeInteger(ppRecord.Cliente__r.SM_Ciudad__r?.SM_PoblacionPrincipal__r?.SM_PoblacionPrincipal__r?.Codigo_poblacion__c));
            if(!addressMap.isEmpty()){
                roleMap.put('direcciones', new List<Map<String, Object>>{ addressMap });
            }
        }
        
        return roleMap;
    }

    private static void putIfNotNull(Map<String, Object> targetMap, String key, Object value) {
        if (value != null) {
            targetMap.put(key, value);
        } else {
            System.debug('[Value MISSING] Campo omitido: "' + key + '" porque el valor llegó nulo.');
        }
    }

    private static void putFromMap(Map<String, Object> targetMap, String jsonKey, String sfValue, Map<String, Object> mappingMap) {
        if (String.isNotBlank(sfValue)) {
            Object mappedValue = mappingMap.get(sfValue);
            if (mappedValue != null) {
                targetMap.put(jsonKey, mappedValue);
            } else {
                System.debug('[MAPPING MISSING] Key omitido: "' + sfValue + '" en el mapa de ' + jsonKey);
            }
        }
    }

    private static Integer safeInteger(String value) {
        try {
            return String.isNotBlank(value) ? Integer.valueOf(value.trim()) : null;
        } catch (Exception e) {
            System.debug('Error de conversión en safeInteger para el valor: ' + value);
            return null;
        }
    }
}