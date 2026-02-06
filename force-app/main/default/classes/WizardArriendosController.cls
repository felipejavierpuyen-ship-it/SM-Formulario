public without sharing class WizardArriendosController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getContextData(Id caseId) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            List<Participante_de_Poliza__c> participantes = [
                SELECT Id, Cliente__c,
                    Cliente__r.FirstName, Cliente__r.LastName, Cliente__r.MiddleName, Cliente__r.Name,
                    Cliente__r.No_de_identificaci_n__c, Cliente__r.SM_TipoDocumento__c,
                    Cliente__r.Fecha_expedicion_documento__c, Cliente__r.Genero__c,
                    Cliente__r.SM_Direccion__c, Cliente__r.SM_Ciudad__c, Cliente__r.SM_Ciudad__r.Name,
                    Cliente__r.SM_Ciudad__r.SM_PoblacionPrincipal__r.Name,
                    Cliente__r.SM_Ciudad__r.SM_PoblacionPrincipal__r.SM_PoblacionPrincipal__r.Name,
                    Cliente__r.PersonMobilePhone, Cliente__r.SM_CorreoElectronico__c, Cliente__r.Email__c,
                    Cliente__r.SM_ActividadEconomica__c, Cliente__r.Sector_Econ_mico__c,
                    Cliente__r.Tipo_de_persona__c, Caso_Relacionado__r.CaseNumber
                FROM Participante_de_Poliza__c 
                WHERE Caso_Relacionado__c = :caseId AND Tipo_de_Participante__c = 'Propietario'
                WITH SYSTEM_MODE LIMIT 1
            ];

            if(!participantes.isEmpty()) {
                Participante_de_Poliza__c p = participantes[0];
                Account acc = p.Cliente__r;

                response.put('caseNumber', p.Caso_Relacionado__r.CaseNumber);
                response.put('tipoPersona', acc.Tipo_de_persona__c != null ? acc.Tipo_de_persona__c : 'Natural');
                
                response.put('tipoDocumento', acc.SM_TipoDocumento__c);
                response.put('numeroDocumento', acc.No_de_identificaci_n__c);

                response.put('primerNombre', acc.FirstName != null ? acc.FirstName : acc.Name);
                response.put('primerApellido', acc.LastName != null ? acc.LastName : '');
                response.put('segundoApellido', acc.MiddleName != null ? acc.MiddleName : '');
                
                response.put('fechaExpedicion', acc.Fecha_expedicion_documento__c);
                response.put('genero', acc.Genero__c);
                response.put('direccion', acc.SM_Direccion__c);
                
                response.put('SM_Ciudad__c', acc.SM_Ciudad__c);
                response.put('ciudadNombre', acc.SM_Ciudad__r.Name);
                response.put('departamento', acc.SM_Ciudad__r.SM_PoblacionPrincipal__r.Name);
                response.put('pais', acc.SM_Ciudad__r.SM_PoblacionPrincipal__r.SM_PoblacionPrincipal__r.Name);
                
                response.put('celular', acc.PersonMobilePhone);
                response.put('email', acc.SM_CorreoElectronico__c);
                response.put('emailFacturacion', acc.Email__c);
                response.put('actividadEconomica', acc.SM_ActividadEconomica__c);
                response.put('sectorEconomico', acc.Sector_Econ_mico__c);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static void saveTableData(List<SObject> recordsToUpsert) {
        if (recordsToUpsert == null || recordsToUpsert.isEmpty()) {
            return;
        }

        try {
            System.debug('Se actualizo');
            
        } catch (DmlException de) {
            String errorMsg = de.getDmlMessage(0);
            throw new AuraHandledException('Error de validación en Salesforce: ' + errorMsg);
        } catch (Exception e) {
            throw new AuraHandledException('Error al intentar guardar la información: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SM_Poblacion__c> searchCities(String searchTerm) {
        String query = '%' + searchTerm + '%';
        return [
            SELECT Id, Name, SM_PoblacionPrincipal__r.Name, SM_PoblacionPrincipal__r.SM_PoblacionPrincipal__r.Name
            FROM SM_Poblacion__c 
            WHERE Name LIKE :query 
            WITH SYSTEM_MODE 
            LIMIT 10
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDetallesInmueble(Id caseId) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            Case c = [SELECT Id, Tipo_de_Inmueble__c, Canon__c, Iva_arriendos__c, 
                            Valor_Administraci_n__c, Modalidad_de_Pago__c, NumeroDeCuenta__c
                    FROM Case WHERE Id = :caseId LIMIT 1];
            
            response.put('Tipo_de_Inmueble__c', c.Tipo_de_Inmueble__c);
            response.put('Canon__c', c.Canon__c);
            response.put('Iva_arriendos__c', c.Iva_arriendos__c);
            response.put('Valor_Administraci_n__c', c.Valor_Administraci_n__c);
            response.put('Modalidad_de_Pago__c', c.Modalidad_de_Pago__c);
            response.put('NumeroDeCuenta__c', c.NumeroDeCuenta__c);

            response.put('servicios', [SELECT Id, Name, Aplica__c, porcentaje_asumido_factura__c 
                                    FROM Servicio_Inmueble__c 
                                    WHERE Caso_Arriendo__c = :caseId]);

            
                                    
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static void saveWizardStep(Id caseId, String payload) {
        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(payload);
            Case currentCase = [SELECT Id, AccountId FROM Case WHERE Id = :caseId LIMIT 1];
            
            Account accToUpdate = new Account(Id = currentCase.AccountId);
            Account checkAcc = [SELECT IsPersonAccount FROM Account WHERE Id = :currentCase.AccountId LIMIT 1];

            if (checkAcc.IsPersonAccount) {
                if(data.containsKey('primerNombre')) accToUpdate.FirstName = (String)data.get('primerNombre');
                if(data.containsKey('primerApellido')) accToUpdate.LastName = (String)data.get('primerApellido');
                if(data.containsKey('email')) accToUpdate.PersonEmail = (String)data.get('email');
            } else {
                if(data.containsKey('primerNombre') || data.containsKey('primerApellido')) {
                    String nom = data.containsKey('primerNombre') ? (String)data.get('primerNombre') : '';
                    String ape = data.containsKey('primerApellido') ? (String)data.get('primerApellido') : '';
                    accToUpdate.Name = (nom + ' ' + ape).trim();
                }
                if(data.containsKey('email')) accToUpdate.Email__c = (String)data.get('email');
            }
            
            //if(data.containsKey('nombresRL')) accToUpdate.SM_NombresRepresentanteLegal__c = (String)data.get('nombresRL');
            //if(data.containsKey('numeroDocumentoRL')) accToUpdate.SM_DocumentoRepresentanteLegal__c = (String)data.get('numeroDocumentoRL');

            update accToUpdate;

            Case caseToUpdate = new Case(Id = caseId);
            if(data.containsKey('Tipo_de_Inmueble__c')) caseToUpdate.Tipo_de_Inmueble__c = (String)data.get('Tipo_de_Inmueble__c');
            if(data.containsKey('Canon__c')) caseToUpdate.Canon__c = Decimal.valueOf(String.valueOf(data.get('Canon__c')));
            if(data.containsKey('Iva_arriendos__c')) caseToUpdate.Iva_arriendos__c = Decimal.valueOf(String.valueOf(data.get('Iva_arriendos__c')));
            if(data.containsKey('Modalidad_de_Pago__c')) caseToUpdate.Modalidad_de_Pago__c = (String)data.get('Modalidad_de_Pago__c');
            if(data.containsKey('NumeroDeCuenta__c')) caseToUpdate.NumeroDeCuenta__c = (String)data.get('NumeroDeCuenta__c');
            
            update caseToUpdate;

            if(data.containsKey('servicios')) {
                upsertServiciosPublicos(caseId, (List<Object>)data.get('servicios'));
            }

        } catch (Exception e) {
            throw new AuraHandledException('Error en saveWizardStep: ' + e.getMessage());
        }
    }

    private static void upsertServiciosPublicos(Id caseId, List<Object> serviciosList) {
        List<Servicio_Inmueble__c> serviciosToUpsert = new List<Servicio_Inmueble__c>();
        
        for(Object obj : serviciosList) {
            Map<String, Object> s = (Map<String, Object>)obj;
            Servicio_Inmueble__c sp = new Servicio_Inmueble__c();
            
            String idStr = (String)s.get('id');
            if(idStr != null && (idStr.length() == 15 || idStr.length() == 18) && !idStr.isNumeric()) {
                sp.Id = (Id)idStr;
            }
            
            sp.Caso_Arriendo__c = caseId;
            sp.Name = (String)s.get('Name');
            sp.Aplica__c = (Boolean)s.get('Aplica__c');
            sp.porcentaje_asumido_factura__c = s.get('porcentaje_asumido_factura__c') != null ? Decimal.valueOf(String.valueOf(s.get('porcentaje_asumido_factura__c'))) : 0;
            
            serviciosToUpsert.add(sp);
        }
        
        if(!serviciosToUpsert.isEmpty()) {
            upsert serviciosToUpsert;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Participante_de_Poliza__c> getShareholders(Id caseId) {
        List<Participante_de_Poliza__c> participantes = [SELECT Id, Tipo_de_Documento__c, Cedula_o_NIT__c, Cliente__c, Cliente__r.Name,
                                                         Nombre_del_Cliente__c, de_Participacion__c, Cotiza_en_bolsa__c,
                                                         Es_PEP__c, Tributa_en_otro_pais__c
                                                         FROM Participante_de_Poliza__c
                                                         WHERE Caso_Relacionado__c = :caseId //AND Tipo_de_Participante__c = 'Accionista'
                                                         WITH SYSTEM_MODE];
        return participantes;
    }
    
    @AuraEnabled
    public static void saveShareholders(List<Participante_de_Poliza__c> participantes) {
        upsert participantes;
    }

}