@isTest
private class SlipTemporaryJsonGenerator_test {

    @testSetup
    static void setupData() {
        // País
        SM_Poblacion__c pais = new SM_Poblacion__c(Name = 'Colombia', Codigo_poblacion__c = '1');
        insert pais;

        // Departamento
        SM_Poblacion__c dpto = new SM_Poblacion__c(
            Name = 'Amazonas', 
            SFC_Codigo__c = '91', 
            SM_PoblacionPrincipal__c = pais.Id
        );
        insert dpto;

        // Ciudad
        SM_Poblacion__c ciudad = new SM_Poblacion__c(
            Name = 'Leticia', 
            SFC_Codigo__c = '91536', 
            SM_Activo__c = true,
            SM_EsCiudad__c = true,
            SM_PoblacionPrincipal__c = dpto.Id
        );
        insert ciudad;

        // Intermediario - Account
        Account inter = new Account(Name = 'Agente Test', cod_agente__c = '13158');
        insert inter;

        // Sucursal
        SM_Sucursal__c sucursal = new SM_Sucursal__c(Name = 'Sucursal Central', SM_Codigo__c = 14);
        insert sucursal;

        // Caso
        Id csArriendoRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Solicitud_de_Arriendos').getRecordTypeId();
        Case cs = new Case(
            Subject = 'Caso Test Temporario',
            Canon__c = 1000,
            Valor_Administraci_n__c = 500,
            Description = 'Garantizar cumplimiento',
            DireccionInmueble__c = 'Calle Falsa 123',
            Telefono_tomador__c = '1234567',
            Moneda__c = 'EUR',
            Ramo__c = 'Arriendos',
            RecordTypeId = csArriendoRT,
            Sucursal__c = sucursal.Id,
            Intermediario__c = inter.Id,
            Fecha_inicio_de_vigencia_de_poliza__c = Date.today(),
            Fecha_fin_de_vigencia_de_poliza__c = Date.today().addYears(1),
            ObservacionesEmision__c = 'Test Obs'
        );
        insert cs;

        // Slip
        Id slipArriendoRT = Schema.SObjectType.Slip__c.getRecordTypeInfosByDeveloperName().get('RT_Arriendos').getRecordTypeId();
        Slip__c slip = new Slip__c(
            RecordTypeId = slipArriendoRT,
            Caso__c = cs.Id,
            Ciudad__c = ciudad.Id,
            Aplica_apropiacion__c = true,
            Codigo_modalidad_de_aseguramiento__c = '1',
            Estado_riesgo__c = 'I',
            Grupo_de_endoso__c = '1',
            Codigo_de_destino_del_inmueble__c = '1',
            Indica_si_aplica_multiples_pagadores__c = false,
            Indica_si_aplica_renovacion_automatica__c = false,
            Indica_si_se_aplica_cobro_de_IVA__c = true,
            Indica_si_se_valida_la_prima_minima__c = true,
            Numero_de_articulos_en_el_inventario__c = 0,
            Numero_de_servicios_publicos__c = 0,
            Punto_de_venta__c = '0',
            Participacion_intermediario__c = 100,
            Renovacion_automatica__c = true,
            Tasa_de_cambio__c = 1,
            Tipo_de_endoso__c = '1',
            Tipo_de_intermediario__c = '1',
            Producto__c = '94',
            Tipo_de_Poliza__c = '3',
            Giro_de_negocio__c = '10',
            Tipo_IVA__c = '1',
            Valor_gastos_de_emisi_n__c = 1000000,
            Coberturas__c = '[{"Id":"01t1","NOMBRE":"CANON"}]'
        );
        insert slip;

        Id personAccRT =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        // Person Account 1
        Account personAcc1 = new Account(
            FirstName = 'Juan',
            LastName = 'Perez',
            PersonEmail = 'test@mail.com',
            Phone = '300123',
            SM_Direccion__c = 'Carrera 1',
            SM_Ciudad__c = ciudad.Id,
            SM_CorreoElectronico__c = 'segurosmundial@colombia.com',
            RecordTypeId = personAccRT
        );
        insert personAcc1;

        // Participantes de Póliza 1
        Participante_de_Poliza__c part1 = new Participante_de_Poliza__c(
            Caso_Relacionado__c = cs.Id,
            Cliente__c = personAcc1.Id,
            Cedula_o_NIT__c = '12345',
            Tipo_de_Participante__c = 'Inquilino',
            Tipo_de_Documento__c = 'Cédula de ciudadanía',
            EsTomador__c = true
        );
        insert part1;
        
        // Person Account
        Account personAcc2 = new Account(
            FirstName = 'Felipe',
            LastName = 'Puyen',
            PersonEmail = 'felipejavierpuyen@gmail.com',
            Phone = '+51957547079',
            SM_Direccion__c = 'Carrera 4',
            SM_Ciudad__c = ciudad.Id,
            SM_CorreoElectronico__c = 'felipejavierpuyen@gmail.com',
            RecordTypeId = personAccRT
        );
        insert personAcc2;
        
        // Participantes de Póliza 2
        Participante_de_Poliza__c part2 = new Participante_de_Poliza__c(
            Caso_Relacionado__c = cs.Id,
            Cliente__c = personAcc2.Id,
            Cedula_o_NIT__c = '77387641',
            Tipo_de_Participante__c = 'Deudor',
            Tipo_de_Documento__c = 'Cédula de ciudadanía',
            EsTomador__c = false
        );
        insert part2;
    }

    @isTest
    static void testGenerateMappingSlipSuccess() {
        Slip__c slip = [SELECT Id FROM Slip__c LIMIT 1];
        
        SlipTemporaryJSONGenerator generator = new SlipTemporaryJSONGenerator();
        Map<String, Object> input = new Map<String, Object>{'SlipId' => slip.Id};
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        generator.invokeMethod('generateMappingSlip', input, outMap, options);
        Test.stopTest();

        // Validaciones
        System.assert(outMap.containsKey('context'), 'Debe contener nodo context');
        System.assert(outMap.containsKey('roles'), 'Debe contener nodo roles');
        
        Map<String, Object> riesgos = (Map<String, Object>)outMap.get('riesgos');
        Map<String, Object> metadataRiesgo = (Map<String, Object>)riesgos.get('metadataRiesgo');
        
        // Validar cálculo de vlrContrato (1000 + 500 del setup)
        System.assertEquals(1500.00, (Decimal)metadataRiesgo.get('vlrContrato'), 'El valor del contrato no coincide');
        
        List<Object> roles = (List<Object>)outMap.get('roles');
        // Debería haber 4 roles por el Participante: AFIANZADO, INQUILINO, ARRENDATARIO y TOMADOR (porque EsTomador__c = true)
        System.assertEquals(4, roles.size(), 'Se esperaban 4 roles para el participante configurado');
    }

    @isTest
    static void testMissingSlipId() {
        SlipTemporaryJSONGenerator generator = new SlipTemporaryJSONGenerator();
        Map<String, Object> input = new Map<String, Object>(); // Sin SlipId
        Map<String, Object> outMap = new Map<String, Object>();
        
        Test.startTest();
        generator.invokeMethod('generateMappingSlip', input, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(false, outMap.get('success'));
        System.assertEquals('El SlipId es requerido.', outMap.get('error'));
    }

    @isTest
    static void testInvalidId() {
        SlipTemporaryJSONGenerator generator = new SlipTemporaryJSONGenerator();
        Map<String, Object> input = new Map<String, Object>{'SlipId' => '001000000000000AAA'}; // ID inválido
        Map<String, Object> outMap = new Map<String, Object>();
        
        Test.startTest();
        generator.invokeMethod('generateMappingSlip', input, outMap, new Map<String, Object>());
        Test.stopTest();

        // Debe capturar el error en el catch de generateMappingSlip
        System.assert(((String)outMap.get('error')).contains('List has no rows for assignment'), 'Debe fallar al no encontrar el registro');
    }
    
    @isTest
    static void testSafeIntegerError() {
        Slip__c slip = [SELECT Id FROM Slip__c LIMIT 1];
        
        // Forzamos un valor NO numérico para que falle y entre al CATCH
        slip.Punto_de_venta__c = 'ERROR_STRING'; 
        update slip;

        SlipTemporaryJSONGenerator generator = new SlipTemporaryJSONGenerator();
        Map<String, Object> input = new Map<String, Object>{'SlipId' => slip.Id};
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        generator.invokeMethod('generateMappingSlip', input, outMap, new Map<String, Object>());
        Test.stopTest();

        Map<String, Object> valueMap = (Map<String, Object>)outMap.get('value');
        System.assertEquals(false, valueMap.containsKey('codPtoVta'), 'La llave no debe existir porque la conversión falló');
    }
    
    @isTest
    static void testInvalidMethodName() {
        SlipTemporaryJSONGenerator generator = new SlipTemporaryJSONGenerator();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        
        Test.startTest();
        Object result = generator.invokeMethod('metodoInexistente', input, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(null, result, 'Si el método no coincide, debe retornar null');
    }
}