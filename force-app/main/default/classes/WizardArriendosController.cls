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
                    Cliente__r.SM_Ciudad__r.SM_PoblacionPrincipal__r.Name,Cliente__r.SM_LugarNacimiento__c,
                    Cliente__r.SM_Ciudad__r.SM_PoblacionPrincipal__r.SM_PoblacionPrincipal__r.Name,
                    Cliente__r.PersonMobilePhone, Cliente__r.SM_CorreoElectronico__c, Cliente__r.Email__c,
                    Cliente__r.SM_Nacionalidad1__c, Cliente__r.SM_Nacionalidad2__c, Cliente__r.SM_EsPEPRL__c,
                    Cliente__r.SM_AdminRecursosPublicosRL__c, Cliente__r.SM_ObligacionesTributariasRL__c,
                    Cliente__r.SM_ActividadEconomica__c, Cliente__r.Sector_Econ_mico__c,Cliente__r.IsPersonAccount,
                    Cliente__r.Tipo_de_persona__c, Cliente__r.Fecha_Formulario_Sarlaft__c, Cliente__r.PersonBirthdate,
                    Cliente__r.Ingresos_Mensuales__c, Cliente__r.Egresos_Mensuales__c, Cliente__r.SMActivos__c,
                    Cliente__r.SMPasivos__c, Cliente__r.SMOtrosIngresos__c, Cliente__r.SMDetalleOrigenFondos__c,
                    Cliente__r.ExpeditionPlace__c, Cliente__r.ExpeditionPlace__r.Name,Caso_Relacionado__r.CaseNumber,
                    Caso_Relacionado__r.Fecha_inicio_Vigencia__c,Caso_Relacionado__r.endDate__c
                FROM Participante_de_Poliza__c 
                WHERE Caso_Relacionado__c = :caseId AND Tipo_de_Participante__c = 'Propietario'
                WITH SYSTEM_MODE LIMIT 1
            ];

            if(!participantes.isEmpty()) {
                Participante_de_Poliza__c p = participantes[0];
                Account acc = p.Cliente__r;

                response.put('caseNumber', p.Caso_Relacionado__r.CaseNumber);
                response.put('Cliente__c', p.Cliente__c);
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
                response.put('Fecha_Formulario_Sarlaft__c', acc.Fecha_Formulario_Sarlaft__c);
                response.put('lugarNacimientoRL', acc.SM_LugarNacimiento__c);
                response.put('nacionalidad1RL', acc.SM_Nacionalidad1__c);
                response.put('nacionalidad2RL', acc.SM_Nacionalidad2__c);
                response.put('isPEPRL', acc.SM_EsPEPRL__c);
                response.put('adminRecursosRL', acc.SM_AdminRecursosPublicosRL__c);
                response.put('obligacionesTributariasRL', acc.SM_ObligacionesTributariasRL__c);
                response.put('direccionRL', acc.SM_Direccion__c);
                response.put('lugarExpedicionRL', acc.ExpeditionPlace__c);
                response.put('lugarExpedicionNombreRL', acc.ExpeditionPlace__r != null ? acc.ExpeditionPlace__r.Name : '');
                if(acc.IsPersonAccount) {
                    response.put('fechaNacimientoRL', acc.PersonBirthdate);
                }
                response.put('ingresosMensuales', acc.Ingresos_Mensuales__c);
                response.put('egresosMensuales', acc.Egresos_Mensuales__c);
                response.put('totalActivos', acc.SMActivos__c);
                response.put('totalPasivos', acc.SMPasivos__c);
                response.put('otrosIngresos', acc.SMOtrosIngresos__c);
                response.put('detalleOrigenFondos', acc.SMDetalleOrigenFondos__c);
                response.put('fechaInicio', p.Caso_Relacionado__r.Fecha_inicio_Vigencia__c);
                response.put('fechaFin', p.Caso_Relacionado__r.endDate__c);
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
                            Valor_Administraci_n__c, Modalidad_de_Pago__c, NumeroDeCuenta__c,
                            SM_LugarPago__c, RecordTypeId 
                    FROM Case WHERE Id = :caseId LIMIT 1];
            
            response.put('Tipo_de_Inmueble__c', c.Tipo_de_Inmueble__c);
            response.put('Canon__c', c.Canon__c);
            response.put('Iva_arriendos__c', c.Iva_arriendos__c);
            response.put('Valor_Administraci_n__c', c.Valor_Administraci_n__c);
            response.put('RecordTypeId', c.RecordTypeId);
            response.put('SM_LugarPago__c', c.SM_LugarPago__c);
            response.put('Modalidad_de_Pago__c', c.Modalidad_de_Pago__c);
            response.put('NumeroDeCuenta__c', c.NumeroDeCuenta__c);

            response.put('serviciosPublicosBD', [SELECT Id, Name, Aplica__c, porcentaje_asumido_factura__c, SM_TipoServicio__c 
                                                FROM Servicio_Inmueble__c 
                                                WHERE Caso_Arriendo__c = :caseId 
                                                AND SM_TipoServicio__c = 'Público']);

            response.put('cosasConexasBD', [SELECT Id, Name, Aplica__c, porcentaje_asumido_factura__c, SM_TipoServicio__c, SM_DescripcionConexo__c  
                                            FROM Servicio_Inmueble__c 
                                            WHERE Caso_Arriendo__c = :caseId 
                                            AND SM_TipoServicio__c = 'CosaConexa']);
                                        
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static void saveWizardStep(Id caseId, String payload) {
        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(payload);
            Id accountId = (Id)data.get('targetAccountId');
            if (accountId == null) {
                Case currentCase = [SELECT Id, AccountId FROM Case WHERE Id = :caseId LIMIT 1];
                accountId = currentCase.AccountId;
            }

            Account accToUpdate = new Account(Id = accountId);
            Account checkAcc = [SELECT IsPersonAccount FROM Account WHERE Id = :accountId LIMIT 1];

            if(data.containsKey('tipoPersona')) accToUpdate.Tipo_de_persona__c = (String)data.get('tipoPersona');
            if(data.containsKey('tipoDocumento')) accToUpdate.SM_TipoDocumento__c = (String)data.get('tipoDocumento');
            if(data.containsKey('numeroDocumento')) accToUpdate.No_de_identificaci_n__c = (String)data.get('numeroDocumento');
            if(data.containsKey('direccion')) accToUpdate.SM_Direccion__c = (String)data.get('direccion');
            if(data.containsKey('SM_Ciudad__c')) accToUpdate.SM_Ciudad__c = (String)data.get('SM_Ciudad__c');
            if(data.containsKey('genero')) accToUpdate.Genero__c = (String)data.get('genero');
            if(data.containsKey('actividadEconomica')) accToUpdate.SM_ActividadEconomica__c = (String)data.get('actividadEconomica');
            if(data.containsKey('sectorEconomico')) accToUpdate.Sector_Econ_mico__c = (String)data.get('sectorEconomico');
            if(data.containsKey('emailFacturacion')) accToUpdate.SM_CorreoElectronico__c = (String)data.get('emailFacturacion');
            
            if(data.containsKey('fechaExpedicion') && data.get('fechaExpedicion') != null && String.valueOf(data.get('fechaExpedicion')) != '') {
                accToUpdate.Fecha_expedicion_documento__c = Date.valueOf((String)data.get('fechaExpedicion'));
            }

            if (checkAcc.IsPersonAccount) {
                if(data.containsKey('primerNombre')) accToUpdate.FirstName = (String)data.get('primerNombre');
                if(data.containsKey('primerApellido')) accToUpdate.LastName = (String)data.get('primerApellido');
                if(data.containsKey('segundoApellido')) accToUpdate.MiddleName = (String)data.get('segundoApellido');
                if(data.containsKey('email')) accToUpdate.PersonEmail = (String)data.get('email');
                if(data.containsKey('celular')) accToUpdate.PersonMobilePhone = (String)data.get('celular');
                if(data.containsKey('fechaNacimientoRL') && data.get('fechaNacimientoRL') != null && String.valueOf(data.get('fechaNacimientoRL')) != '') {
                    accToUpdate.PersonBirthdate = Date.valueOf((String)data.get('fechaNacimientoRL'));
                }
            } else {
                if(data.containsKey('primerNombre') || data.containsKey('primerApellido')) {
                    String nom = data.containsKey('primerNombre') ? (String)data.get('primerNombre') : '';
                    String ape = data.containsKey('primerApellido') ? (String)data.get('primerApellido') : '';
                    String ape2 = data.containsKey('segundoApellido') ? (String)data.get('segundoApellido') : '';
                    accToUpdate.Name = (nom + ' ' + ape + ' ' + ape2).trim();
                }
                if(data.containsKey('email')) accToUpdate.Email__c = (String)data.get('email'); 
                if(data.containsKey('celular')) accToUpdate.Phone = (String)data.get('celular');
            }

            if(data.containsKey('ingresosMensuales')) accToUpdate.Ingresos_Mensuales__c = Decimal.valueOf(String.valueOf(data.get('ingresosMensuales')));
            if(data.containsKey('egresosMensuales')) accToUpdate.Egresos_Mensuales__c = Decimal.valueOf(String.valueOf(data.get('egresosMensuales')));
            if(data.containsKey('totalActivos')) accToUpdate.SMActivos__c = Decimal.valueOf(String.valueOf(data.get('totalActivos')));
            if(data.containsKey('totalPasivos')) accToUpdate.SMPasivos__c = Decimal.valueOf(String.valueOf(data.get('totalPasivos')));
            if(data.containsKey('otrosIngresos')) accToUpdate.SMOtrosIngresos__c = Decimal.valueOf(String.valueOf(data.get('otrosIngresos')));
            if(data.containsKey('detalleOrigenFondos')) accToUpdate.SMDetalleOrigenFondos__c = (String)data.get('detalleOrigenFondos');
            if(data.containsKey('lugarExpedicionRL')) accToUpdate.ExpeditionPlace__c = (Id)data.get('lugarExpedicionRL');
            if(data.containsKey('direccionRL')) accToUpdate.SM_Direccion__c = (String)data.get('direccionRL');
            if(data.containsKey('lugarNacimientoRL')) accToUpdate.SM_LugarNacimiento__c = (String)data.get('lugarNacimientoRL');
            if(data.containsKey('nacionalidad1RL')) accToUpdate.SM_Nacionalidad1__c = (String)data.get('nacionalidad1RL');
            if(data.containsKey('nacionalidad2RL')) accToUpdate.SM_Nacionalidad2__c = (String)data.get('nacionalidad2RL');
            if(data.containsKey('isPEPRL')) accToUpdate.SM_EsPEPRL__c = (String)data.get('isPEPRL');
            if(data.containsKey('adminRecursosRL')) accToUpdate.SM_AdminRecursosPublicosRL__c = (String)data.get('adminRecursosRL');
            if(data.containsKey('obligacionesTributariasRL')) accToUpdate.SM_ObligacionesTributariasRL__c = (String)data.get('obligacionesTributariasRL');

            update accToUpdate;

            Case caseToUpdate = new Case(Id = caseId);
            
            Id arriendosRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Solicitud_de_Arriendos').getRecordTypeId();
            caseToUpdate.RecordTypeId = arriendosRT;

            if(data.containsKey('Tipo_de_Inmueble__c')) caseToUpdate.Tipo_de_Inmueble__c = (String)data.get('Tipo_de_Inmueble__c');
            if(data.containsKey('Canon__c')) caseToUpdate.Canon__c = Decimal.valueOf(String.valueOf(data.get('Canon__c')));
            if(data.containsKey('Iva_arriendos__c')) caseToUpdate.Iva_arriendos__c = Decimal.valueOf(String.valueOf(data.get('Iva_arriendos__c')));
            if(data.containsKey('Valor_Administraci_n__c')) caseToUpdate.Valor_Administraci_n__c = Decimal.valueOf(String.valueOf(data.get('Valor_Administraci_n__c')));
            if(data.containsKey('Modalidad_de_Pago__c')) caseToUpdate.Modalidad_de_Pago__c = (String)data.get('Modalidad_de_Pago__c');
            if(data.containsKey('NumeroDeCuenta__c')) caseToUpdate.NumeroDeCuenta__c = (String)data.get('NumeroDeCuenta__c');
            if(data.containsKey('SM_LugarPago__c')) caseToUpdate.SM_LugarPago__c = (String)data.get('SM_LugarPago__c');

            update caseToUpdate;

            if(data.containsKey('servicios')) {
                upsertServiciosPublicos(caseId, (List<Object>)data.get('servicios'));
            }

            if(data.containsKey('clausulasSeleccionadas')) {
                upsertClausulasAdicionales(caseId, (List<Object>)data.get('clausulasSeleccionadas'));
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
            
            if(s.containsKey('SM_DescripcionConexo__c')) {
                sp.SM_DescripcionConexo__c = (String)s.get('SM_DescripcionConexo__c');
            }

            if(s.containsKey('SM_TipoServicio__c')) {
                sp.SM_TipoServicio__c = (String)s.get('SM_TipoServicio__c');
            } else {
                sp.SM_TipoServicio__c = 'ServicioPublico';
            }
            serviciosToUpsert.add(sp);
        }
        if(!serviciosToUpsert.isEmpty()) upsert serviciosToUpsert;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Participante_de_Poliza__c> getShareholders(Id caseId) {
        List<Participante_de_Poliza__c> participantes = [SELECT Id, Tipo_de_Documento__c, Cedula_o_NIT__c, Cliente__c, Cliente__r.Name,
                                                         Nombre_del_Cliente__c, de_Participacion__c, Cotiza_en_bolsa__c,
                                                         Es_PEP__c, Tributa_en_otro_pais__c
                                                         FROM Participante_de_Poliza__c
                                                         WHERE Caso_Relacionado__c = :caseId AND Tipo_de_Participante__c = 'Accionista'
                                                         WITH SYSTEM_MODE];
        return participantes;
    }
    
    @AuraEnabled
    public static void createShareholder(Map<String, Object> fieldsMap) {
        try {
            Participante_de_Poliza__c nuevoSocio = new Participante_de_Poliza__c();
            nuevoSocio.Caso_Relacionado__c = (Id)fieldsMap.get('Caso_Relacionado__c');
            nuevoSocio.Nombre_del_Cliente__c = (String)fieldsMap.get('Nombre_del_Cliente__c');
            nuevoSocio.Tipo_de_Documento__c = (String)fieldsMap.get('Tipo_de_Documento__c');
            nuevoSocio.Cedula_o_NIT__c = (String)fieldsMap.get('Cedula_o_NIT__c');
            nuevoSocio.de_Participacion__c = Decimal.valueOf(String.valueOf(fieldsMap.get('de_Participacion__c')));
            nuevoSocio.Cotiza_en_bolsa__c = (String)fieldsMap.get('Cotiza_en_bolsa__c');
            nuevoSocio.Es_PEP__c = (String)fieldsMap.get('Es_PEP__c');
            nuevoSocio.Tributa_en_otro_pais__c = (String)fieldsMap.get('Tributa_en_otro_pais__c');
            nuevoSocio.Tipo_de_Participante__c = 'Accionista';
            insert nuevoSocio;
        } catch (Exception e) {
            throw new AuraHandledException('Error al crear: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SM_ClausuladoAdicional__mdt> getClausulasMetadata(String tipo) {
        return [
            SELECT Label, DeveloperName, SM_ContenidoCompleto__c, Orden__c 
            FROM SM_ClausuladoAdicional__mdt 
            WHERE SM_TipoInmueble__c = :tipo
            ORDER BY Orden__c ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<SM_ClausulaAdicionalSeleccionada__c> getClausulasGuardadas(Id caseId) {
        return [SELECT Id, DeveloperName__c, Seleccionado__c FROM SM_ClausulaAdicionalSeleccionada__c WHERE Caso__c = :caseId];
    }

    @AuraEnabled
    public static void guardarClausulas(Id caseId, List<SM_ClausulaAdicionalSeleccionada__c> listaClausulas) {
        try {
            delete [SELECT Id FROM SM_ClausulaAdicionalSeleccionada__c WHERE Caso__c = :caseId];
            
            if (listaClausulas != null && !listaClausulas.isEmpty()) {
                insert listaClausulas;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar cláusulas: ' + e.getMessage());
        }
    }

    private static void upsertClausulasAdicionales(Id caseId, List<Object> clausulasList) {
        delete [SELECT Id FROM SM_ClausulaAdicionalSeleccionada__c WHERE Caso__c = :caseId];

        List<SM_ClausulaAdicionalSeleccionada__c> clausulasToInsert = new List<SM_ClausulaAdicionalSeleccionada__c>();
        
        for(Object obj : clausulasList) {
            Map<String, Object> c = (Map<String, Object>)obj;
            SM_ClausulaAdicionalSeleccionada__c nueva = new SM_ClausulaAdicionalSeleccionada__c();
            
            nueva.Caso__c = caseId;
            nueva.SM_ContenidoLegal__c = (String)c.get('Contenido_Legal__c');
            nueva.DeveloperName__c = (String)c.get('DeveloperName__c');
            
            if(c.get('Orden__c') != null) {
                nueva.Orden__c = Decimal.valueOf(String.valueOf(c.get('Orden__c')));
            }
            
            nueva.Seleccionado__c = (Boolean)c.get('Seleccionado__c');
            
            clausulasToInsert.add(nueva);
        }

        if(!clausulasToInsert.isEmpty()) {
            insert clausulasToInsert;
        }
    }
}