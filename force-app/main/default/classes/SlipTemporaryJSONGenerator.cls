/**
* @description SlipTemporaryJsonGenerator
* Genera la estructura JSON requerida para el proceso de Temporarios.
* Mapeo basado en DRMappingJSONSlip.
*/
global without sharing class SlipTemporaryJSONGenerator implements vlocity_ins.VlocityOpenInterface2 {
    private static final Integer COD_TEL_PRINCIPAL = 8;
    private static final Integer COD_EMAIL_PRINCIPAL = 10;
    private static final Integer COD_AGRUPADOR = 0;
    private static final String COD_APP = 'salesforce';
    private static final String MODULO = 'casos';
    private static final String COD_USUARIO = 'john.doe';     
    private static final String OPERACION = 'crear-temporario';
    private static final Map<String, Object> RAMO_MAP = new Map<String, Object>{
        'Arriendos' => 60 };
    private static final Map<String, Object> CURRENCY_MAP = new Map<String, Object>{
        'COP' => 0,
		'USD' => 2,
		'EUR' => 10 };
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
                
    global Object invokeMethod(String method, Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        if (method == 'generateMappingSlip') {
            String slipId = (String) input.get('SlipId');
            if (String.isBlank(slipId)) {
                return setError(outMap, 'El SlipId es requerido.');
            }
            generateMappingSlip(slipId, outMap);
            return outMap;
        }
        return null;
    }
    
    private void generateMappingSlip(String slipId, Map<String, Object> outMap) {
        try {
            Slip__c slip = [
                SELECT Id, Name, Caso__c, Aplica_apropiacion__c, Ciudad__c, Ciudad__r.SFC_Codigo__c, Ciudad__r.SM_PoblacionPrincipal__c,
                Ciudad__r.SM_PoblacionPrincipal__r.SFC_Codigo__c, Ciudad__r.SM_PoblacionPrincipal__r.SM_PoblacionPrincipal__r.Codigo_poblacion__c,
                Ciudad__r.SM_PoblacionPrincipal__r.SM_PoblacionPrincipal__c, Coberturas__c, Indica_si_aplica_a_entidad_oficial__c,
                Codigo_modalidad_de_aseguramiento__c, Estado_riesgo__c, Giro_de_negocio__c, Grupo_de_endoso__c, Codigo_de_destino_del_inmueble__c, 
                Indica_si_aplica_multiples_pagadores__c, Indica_si_aplica_renovacion_automatica__c,Indica_si_se_aplica_cobro_de_IVA__c,
                Indica_si_se_valida_la_prima_minima__c, Numero_de_articulos_en_el_inventario__c, Numero_de_servicios_publicos__c, Punto_de_venta__c,
                Participacion_intermediario__c, Renovacion_automatica__c, Tasa_de_cambio__c, Tipo_de_endoso__c, Tipo_de_intermediario__c,
                Tipo_de_Poliza__c, Tipo_IVA__c, Valor_gastos_de_emisi_n__c
                FROM Slip__c 
                WHERE Id = :slipId LIMIT 1
            ];
            
            Case csRecord = [
                SELECT Id, CaseNumber, Canon__c, Description, DireccionInmueble__c, Valor_Administraci_n__c, Intermediario__r.cod_agente__c,
                Fecha_inicio_de_vigencia_de_poliza__c, Fecha_fin_de_vigencia_de_poliza__c,Intermediario__c, Moneda__c,
                ObservacionesEmision__c, Ramo__c,Sucursal__c, Sucursal__r.SM_Codigo__c, Telefono_tomador__c, Owner.Alias
                FROM Case 
                WHERE Id = :slip.Caso__c LIMIT 1
            ];
            
            List<Participante_de_Poliza__c> lstPart = [
                SELECT Id, Cedula_o_NIT__c, Tipo_de_Documento__c, Tipo_de_Participante__c, Cliente__c, EsTomador__c, Cliente__r.SM_Direccion__c,
                Cliente__r.FirstName, Cliente__r.LastName, Cliente__r.Phone, Cliente__r.SM_CorreoElectronico__c, Cliente__r.SM_Ciudad__c,
                Cliente__r.SM_Ciudad__r.SFC_Codigo__c, Cliente__r.SM_Ciudad__r.SM_PoblacionPrincipal__c,
                Cliente__r.SM_Ciudad__r.SM_PoblacionPrincipal__r.SFC_Codigo__c, Cliente__r.SM_Ciudad__r.SM_PoblacionPrincipal__r.SM_PoblacionPrincipal__c,
                Cliente__r.SM_Ciudad__r.SM_PoblacionPrincipal__r.SM_PoblacionPrincipal__r.Codigo_poblacion__c
                FROM Participante_de_Poliza__c
                WHERE Caso_Relacionado__c = :csRecord.Id
            ];
            
            outMap.put('context', mapContext());
            outMap.put('coberturas', String.isNotBlank(slip.Coberturas__c) ? JSON.deserializeUntyped(slip.Coberturas__c) : new Map<String, Object>());
            // Secciones principales: solo se agregan si traen datos
            putIfNotEmpty(outMap, 'value', mapValue(slip, csRecord));
            putIfNotEmpty(outMap, 'riesgos', mapRiesgos(slip, csRecord));
            putIfNotEmpty(outMap, 'roles', mapRoles(lstPart, slip));
            putIfNotEmpty(outMap, 'intermediarios', lstMapIntermediarios(slip, csRecord));
            System.debug('>>> ESTRUCTURA FINAL:\n' + JSON.serializePretty(outMap));
            
            outMap.put('success', true); 
            outMap.put('error', 'OK');
        } catch (Exception e) {
            outMap.put('success', false);
            outMap.put('error', e.getMessage());
        }
    }
    
    private Map<String, Object> mapContext() {
        Map<String, Object> context = new Map<String, Object>();
        String globalKey = UUID.randomUUID().toString();
        Long unixTimestampSeconds = DateTime.now().getTime() / 1000;
        context.put('codApp', COD_APP);
        context.put('modulo', MODULO);
        context.put('codUsuario', COD_USUARIO);
        context.put('operacion', OPERACION);
        context.put('idTrxExt', globalKey);
        context.put('timestamp', unixTimestampSeconds);
        return context;
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
    
    private Map<String, Object> mapValue(Slip__c slip, Case csRecord){
        Map<String, Object> value = new Map<String, Object>();
        putIfNotNull(value, 'nroRadicado', safeInteger(csRecord.CaseNumber));
        putIfNotNull(value, 'descObjPol', csRecord.Description);
        putIfNotNull(value, 'fecIniVigencia', csRecord.Fecha_inicio_de_vigencia_de_poliza__c);
        putIfNotNull(value, 'fecFinVigencia', csRecord.Fecha_fin_de_vigencia_de_poliza__c);
        putIfNotNull(value, 'descAclaratorioPol', csRecord.ObservacionesEmision__c);
        putIfNotNull(value, 'codUsuario', csRecord.Owner?.Alias);
        putIfNotNull(value, 'esPolizaRenovable', slip.Indica_si_aplica_renovacion_automatica__c);
        putIfNotNull(value, 'renovacionAuto', slip.Renovacion_automatica__c);
        putIfNotNull(value, 'impCambioEmision', slip.Tasa_de_cambio__c);
        putIfNotNull(value, 'vlrGastosEmision', slip.Valor_gastos_de_emisi_n__c);
        putIfNotNull(value, 'codAgrupador', COD_AGRUPADOR);
        putIfNotNull(value, 'codSucursal', csRecord.Sucursal__r?.SM_Codigo__c);
        putIfNotNull(value, 'codGrupoEndo', safeInteger(slip.Grupo_de_endoso__c));
        putIfNotNull(value, 'codPtoVta', safeInteger(slip.Punto_de_venta__c));
        putIfNotNull(value, 'codTipoEndo', safeInteger(slip.Tipo_de_endoso__c));
        putIfNotNull(value, 'codTipoPol', safeInteger(slip.Tipo_de_Poliza__c));
        //Evaluar en los Map
        putFromMap(value, 'codMonedaEmision', csRecord.Moneda__c, CURRENCY_MAP);
        putFromMap(value, 'codRamo', csRecord.Ramo__c, RAMO_MAP);
        
        // Poblar el mapa interno: metaDataNegocio
        Map<String, Object> metaDataNegocio = new Map<String, Object>();
        putIfNotNull(metaDataNegocio, 'aplicaApropiacionPresupuestal', slip.Aplica_apropiacion__c);
        putIfNotNull(metaDataNegocio, 'codModalidadAseg', safeInteger(slip.Codigo_modalidad_de_aseguramiento__c));
        putIfNotNull(metaDataNegocio, 'aplicaEntidadOficial', slip.Indica_si_aplica_a_entidad_oficial__c);
        putIfNotNull(metaDataNegocio, 'aplicaVariosPagadores', slip.Indica_si_aplica_multiples_pagadores__c);
        putIfNotNull(metaDataNegocio, 'aplicaCobroIva', slip.Indica_si_se_aplica_cobro_de_IVA__c);
        putIfNotNull(metaDataNegocio, 'aplicaValidacionPrimaMinima', slip.Indica_si_se_valida_la_prima_minima__c);
        if (!metaDataNegocio.isEmpty()) {
            value.put('metadataNegocio', metaDataNegocio);
        }
        
        return value;
    }
    
    private Map<String, Object> mapRiesgos(Slip__c slipRecord, Case csRecord){
        Map<String, Object> riesgos = new Map<String, Object>();
        putIfNotNull(riesgos, 'estado', slipRecord.Estado_riesgo__c);
        putIfNotNull(riesgos, 'codGiroNegocio', safeInteger(slipRecord.Giro_de_negocio__c));
        // Poblar el mapa interno: metadataRiesgo
        Map<String, Object> metadataRiesgo = new Map<String, Object>();
        Decimal vlrContrato = (csRecord.Canon__c ?? 0) + (csRecord.Valor_Administraci_n__c ?? 0);
        putIfNotNull(metadataRiesgo, 'vlrContrato', vlrContrato);
        putIfNotNull(metadataRiesgo, 'canonArrendamiento', csRecord.Canon__c);
        putIfNotNull(metadataRiesgo, 'nroSolicitud', safeInteger(csRecord.CaseNumber));
        putIfNotNull(metadataRiesgo, 'direccion', csRecord.DireccionInmueble__c);
        putIfNotNull(metadataRiesgo, 'telefono', csRecord.Telefono_tomador__c);
        putIfNotNull(metadataRiesgo, 'cuotaAdmin', csRecord.Valor_Administraci_n__c);
        putIfNotNull(metadataRiesgo, 'codMunicipio', safeInteger(slipRecord.Ciudad__r?.SFC_Codigo__c));
        putIfNotNull(metadataRiesgo, 'codDpto', safeInteger(slipRecord.Ciudad__r?.SM_PoblacionPrincipal__r?.SFC_Codigo__c));
        putIfNotNull(metadataRiesgo, 'codPais', safeInteger(slipRecord.Ciudad__r?.SM_PoblacionPrincipal__r?.SM_PoblacionPrincipal__r?.Codigo_poblacion__c));
        putIfNotNull(metadataRiesgo, 'codDestinoInmueble', safeInteger(slipRecord.Codigo_de_destino_del_inmueble__c));
        putIfNotNull(metadataRiesgo, 'nroInventarioArticulos', slipRecord.Numero_de_articulos_en_el_inventario__c);
        putIfNotNull(metadataRiesgo, 'nroServiciosPublicos', slipRecord.Numero_de_servicios_publicos__c);
        if (!metadataRiesgo.isEmpty()) {
            riesgos.put('metadataRiesgo', metadataRiesgo);
        }
        
        return riesgos;
    }
    
    private List<Map<String, Object>> lstMapIntermediarios(Slip__c slipRecord, Case csRecord){
        List<Map<String, Object>> intermList = new List<Map<String, Object>>();
        Map<String, Object> interm = new Map<String, Object>();
        putIfNotNull(interm, 'codAgente', safeInteger(csRecord.Intermediario__r?.cod_agente__c));
        putIfNotNull(interm, 'pjeParticipacion', slipRecord.Participacion_intermediario__c);
        putIfNotNull(interm, 'codTipo', safeInteger(slipRecord.Tipo_de_intermediario__c));
        if (!interm.isEmpty()) {
            intermList.add(interm);
        }
        
        return intermList;
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
    
    private Object setError(Map<String, Object> outMap, String msg) {
        outMap.put('success', false);
        outMap.put('error', msg);
        return outMap;
    }
    
    private static Integer safeInteger(String value) {
        try {
            return String.isNotBlank(value) ? Integer.valueOf(value.trim()) : null;
        } catch (Exception e) {
            System.debug('Error de conversión en safeInteger para el valor: ' + value);
            return null;
        }
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
    
    private static void putIfNotEmpty(Map<String, Object> outMap, String key, Object value) {
        if (value == null) return;
        // Si es un Mapa, checar si tiene llaves
        if (value instanceof Map<String, Object> && !((Map<String, Object>)value).isEmpty()) {
            outMap.put(key, value);
        } 
        // Si es una Lista, checar si tiene elementos
        else if (value instanceof List<Object> && !((List<Object>)value).isEmpty()) {
            outMap.put(key, value);
        }
    }
}