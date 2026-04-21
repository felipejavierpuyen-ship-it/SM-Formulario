import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FlexcardWrapperReusableArriendo extends OmniscriptBaseMixin(LightningElement) {
  @api records = [];
  @api filterBy = {};
  @api allowRowSelection = false;
  @api title;
  @api hiddenColumns = [];
  @api showAddButton = false;
  @api responseNode;
  @api recordId;
  @api areRecordsOptions = false;
  @api isFromProductCatalog = false;

  //Add JR
  @api fechaInicioGlobal;
  @api fechaFinGlobal;

  /**
   * Field schema hardcoded.
   * Añadido: displayLabel para controlar la etiqueta visual de la columna.
   * Ejemplo: FechaInicio se mostrará como "Fecha  de Inicio" pero internamente sigue siendo FechaInicio.
   */
  @api fieldSchema = {
    NOMBRE: { type: 'text' },
    codRamo: { type: 'number', typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 0 } },
    codSubRamo: { type: 'number', typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 0 } },
    codAmparo: { type: 'number', typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 0 } },
    codObjSeg: { type: 'number', typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 0 } },
    'vlrAsegurable': {
      displayLabel: 'Valor Asegurable',
      type: 'currency',
      typeAttributes: { currencyCode: 'COP', minimumFractionDigits: 0, maximumFractionDigits: 0 }
    },
    'sumaAsegurada': {
      displayLabel: 'Suma Asegurada',
      type: 'currency',
      typeAttributes: { currencyCode: 'COP', minimumFractionDigits: 0, maximumFractionDigits: 0 }
    },    
    pjeContrato: { 
      displayLabel: 'Porcentaje Contrato',
      type: 'picklistType', 
      // editable: true, <-- QUITA ESTO, causa el bloqueo del lapicito
      typeAttributes: {
          placeholder: 'Seleccione...',
          options: [
              { label: '$', value: 1 },
              { label: '%', value: 100 },
              { label: '%oo', value: 1000 }
          ],
          value: { fieldName: 'pjeContrato' },
          context: { fieldName: 'Id' }
      }
    },
    CodTipoPolizaSISE: { 
      type: 'number', 
      typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 0 } 
    },
    //'tasa': {
      //type: 'percent',
      //typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 }
    //},
    tasa: { 
      displayLabel: 'Tasa',
      type: 'number', 
      typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 } 
    },
    
    fecIniVigCober: {
      displayLabel: 'Fecha Inicio Vigencia',
      type: 'date-local',
      typeAttributes: {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        timeZone: 'America/Bogota' // o UTC
      }
    },
    fecFinVigCober: {
      displayLabel: 'Fecha Fin Vigencia',
      type: 'date-local',
      typeAttributes: {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        timeZone: 'America/Bogota' // o UTC
      }
    },
    EsOpcional: { type: 'boolean' }
  };

  @track data = [];
  @track draftValues = [];
  columns = [];
  @track isOpen = true;

  requiredFieldsCoberturas = {
    NOMBRE: { required: true },
    codRamo: { required: true },
    codSubRamo: { required: true },
    codAmparo: { required: true },
    codObjSeg: { required: true },
    pjeContrato: { required: true },
    sumaAsegurada: { required: true },
    tasa: { required: true },
    vlrAsegurable: { required: true },
    fecIniVigCober: { required: true },
    fecFinVigCober: { required: true }
  };

  get iconName() {
    return this.isOpen ? 'utility:switch' : 'utility:chevronright';
  }

  toggleSection() {
    this.isOpen = !this.isOpen;
  }

  // Helper: convierte distintos formatos a YYYY-MM-DD o devuelve null.
  _toIsoDate(value) {
    if (!value) return null;

    // Caso: YYYY-MM-DD
    if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value)) {
      return value;
    }

    // Caso: ISO con hora (ej: 2025-12-02T15:30:00Z)
    if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(value)) {
      return value.substring(0, 10); // 👈 recorta solo la fecha
    }

    // Caso: objeto Date
    if (value instanceof Date && !Number.isNaN(value.getTime())) {
      const yyyy = value.getUTCFullYear();
      const mm = String(value.getUTCMonth() + 1).padStart(2, '0');
      const dd = String(value.getUTCDate()).padStart(2, '0');
      return `${yyyy}-${mm}-${dd}`;
    }

    return null;
  }

  connectedCallback() {
    const filtered = this.applyFilter(this.records, this.filterBy);

    console.log('this.fechaInicioGlobal '+this.fechaInicioGlobal);
    console.log('this.fechaFinGlobal '+this.fechaFinGlobal);

    const normalized = Array.isArray(filtered)
      ? filtered.map(row => {
          const cloned = { ...row };
          const raw = cloned.AtributosAdicionales;
          if (raw && typeof raw === 'string') {
            try {
              cloned.AtributosAdicionales = JSON.parse(raw);
            } catch (e) {
              console.warn('Error al parsear AtributosAdicionales:', e);
            }
          }
          return cloned;
        })
      : [];

    const sorted = Array.isArray(normalized) && normalized.length
      ? [...normalized].sort((a, b) => {
          const aVal = a.Ordenamiento !== undefined ? parseInt(a.Ordenamiento, 10) : 0;
          const bVal = b.Ordenamiento !== undefined ? parseInt(b.Ordenamiento, 10) : 0;
          return aVal - bVal;
        })
      : normalized;

    const usedIds = new Set();
    this.data = sorted.map((row, index) => {
      const originalId = row.Id !== undefined && row.Id !== null ? String(row.Id) : null;
      let idValue = originalId || `row-${Date.now()}-${index}`;
      if (usedIds.has(idValue)) {
        idValue = `${idValue}-${index}-${Math.random().toString(36).substr(2, 4)}`;
      }
      usedIds.add(idValue);

      let nombreValue = row.NOMBRE;
      if (this.areRecordsOptions && !nombreValue) {
        const previous = index > 0 ? sorted[index - 1].NOMBRE || '' : '';
        const regex = /^([^\d]+)\s(\d+)$/;
        const match = previous.trim().match(regex);
        if (match) {
          const baseText = match[1].trim();
          const nextNumber = parseInt(match[2], 10) + 1;
          nombreValue = `${baseText} ${nextNumber}`;
        } else {
          nombreValue = `Opción ${index + 1}`;
        }
      }

      const normalizedRow = { ...row };
      Object.keys(this.fieldSchema).forEach(key => {
        if (normalizedRow[key] === undefined || normalizedRow[key] === null) return;
        const schema = this.fieldSchema[key];
        if (!schema) return;
        const val = normalizedRow[key];
        if (val === '' || val === null || val === undefined) return;

        if (schema.type === 'number' || schema.type === 'currency' || schema.type === 'percent') {
          const n = Number(val);
          if (!Number.isNaN(n)) normalizedRow[key] = n;
        } else if (schema.type === 'boolean') {
          normalizedRow[key] = val === true || val === 'true' || val === '1' || val === 1;
        } else if (schema.type === 'date') {
          normalizedRow[key] = this._toIsoDate(val);
        }
        //Add JR Prediligenciamiento de las fechas
        if (!normalizedRow.fecIniVigCober && this.fechaInicioGlobal) {
            normalizedRow.fecIniVigCober = this._toIsoDate(this.fechaInicioGlobal);
        }
        if (!normalizedRow.fecFinVigCober && this.fechaFinGlobal) {
            normalizedRow.fecFinVigCober = this._toIsoDate(this.fechaFinGlobal);
        }
      });

      const { Id, NOMBRE, CATEGORIA, ...rest } = normalizedRow;

      const formattedRow = {
        Id: idValue,
        ...(originalId && originalId !== idValue ? { OriginalId: originalId } : {}),
        NOMBRE: nombreValue || NOMBRE,
        ...(CATEGORIA !== undefined ? { CATEGORIA } : {}),
        ...rest
      };

      return formattedRow;
    });

    this.generateColumns();

    // Evaluar completitud inicial y mandar bandera
    this._updateCompletenessStatus();

    // Empujar payload inicial al OmniScript
    const payloadToSend = this._mapDataForOutbound(this.data);
    this.omniApplyCallResp({ [this.responseNode]: payloadToSend });
  }

  get hideCheckboxColumn() {
    return !this.allowRowSelection;
  }

  applyFilter(data, criteria) {
    if (!Array.isArray(data)) return [];
    if (!criteria || Object.keys(criteria).length === 0) return data;
    return data.filter(row =>
      Object.entries(criteria).every(([key, value]) => row[key] === value)
    );
  }

  generateColumns() {
    const buildColFromKey = key => {
        const schema = this.fieldSchema[key] || { type: 'text' };
        const label = schema.displayLabel || (key === 'NOMBRE' ? 'Nombre' : key);
        
        const col = {
            label,
            fieldName: key,
            // Si el tipo es 'picklistType', NO debe ser editable:true 
            // porque el picklist ya es interactivo por sí solo.
            editable: schema.type === 'picklistType' ? false : true, 
            type: schema.type || 'text'
        };

        if (schema.typeAttributes) col.typeAttributes = { ...schema.typeAttributes };
        if (['number', 'currency', 'percent'].includes(col.type)) col.cellAttributes = { alignment: 'right' };
        return col;
    };

    if (!this.data.length) {
      const schemaKeys = Object.keys(this.fieldSchema);
      if (!schemaKeys.length) return;
      this.columns = schemaKeys
        .filter(key => key !== 'Id' && !this.hiddenColumns.includes(key))
        .map(buildColFromKey);
    } else {
      const sampleRow = this.data[0];
      const allKeys = Object.keys(sampleRow).filter(k => k !== 'Id' && k !== 'OriginalId');

      const reorderedKeys = allKeys.includes('NOMBRE')
        ? ['NOMBRE', ...allKeys.filter(k => k !== 'NOMBRE')]
        : allKeys;

      this.columns = reorderedKeys
        .filter(key => !this.hiddenColumns.includes(key))
        .map(buildColFromKey);
    }

    // Botones de acción al final
    this.columns.push(
      {
        type: 'button-icon',
        fixedWidth: 40,
        typeAttributes: {
          iconName: 'utility:delete',
          title: 'Eliminar',
          name: 'delete',
          variant: 'bare',
          alternativeText: 'Eliminar'
        },
        cellAttributes: { alignment: 'center' }
      },
      {
        type: 'button-icon',
        fixedWidth: 40,
        typeAttributes: {
          iconName: 'utility:up',
          title: 'Mover Arriba',
          name: 'moveUp',
          variant: 'brand'
        }
      },
      {
        type: 'button-icon',
        fixedWidth: 40,
        typeAttributes: {
          iconName: 'utility:down',
          title: 'Mover Abajo',
          name: 'moveDown',
          variant: 'base'
        }
      }
    );
  }

  handleAddRow() {
    const newRow = {};
    const keys = this.columns && this.columns.length
      ? this.columns.map(c => c.fieldName).filter(Boolean)
      : Object.keys(this.fieldSchema);

    keys.forEach(key => {
      if (!key) return;
      const schema = this.fieldSchema[key] || { type: 'text' };
      switch (schema.type) {
        case 'number':
        case 'currency':
        case 'percent':
          newRow[key] = null;
          break;
        case 'boolean':
          newRow[key] = false;
          break;
        case 'date':
          newRow[key] = null;
          break;
        default:
          newRow[key] = '';
      }
    });

    const uniqueId = `row-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`;
    newRow.Id = uniqueId;
    newRow.NOMBRE = this.generateNextName();
    //Add JR Prediligenciamiento de las fechas
    console.log('this.fechaInicioGlobal 2 '+this.fechaInicioGlobal);
    console.log('this.fechaFinGlobal 2 '+this.fechaFinGlobal);
    newRow.fecIniVigCober = this._toIsoDate(this.fechaInicioGlobal);
    newRow.fecFinVigCober = this._toIsoDate(this.fechaFinGlobal);

    let formattedRow = {};
    if (this.responseNode === 'Coberturas') {
      formattedRow = {
        Id: newRow.Id,
        NOMBRE: newRow.NOMBRE,
        EsOpcional: false,
        ...Object.fromEntries(
          Object.entries(newRow).filter(([key]) => key !== 'Id' && key !== 'NOMBRE')
        )
      };
    } else {
      formattedRow = {
        Id: newRow.Id,
        NOMBRE: newRow.NOMBRE,
        ...Object.fromEntries(
          Object.entries(newRow).filter(([key]) => key !== 'Id' && key !== 'NOMBRE')
        )
      };
    }

    this.data = [...this.data, formattedRow];

    // Actualiza bandera y payload
    this._updateCompletenessStatus();
    const payloadToSend = this._mapDataForOutbound(this.data);
    this.omniApplyCallResp({ [this.responseNode]: payloadToSend });
    this.callIntegrationProcedure(payloadToSend);
  }

  generateNextName() {
    if (!this.data.length) return 'Opción 1';
    const lastName = this.data[this.data.length - 1].NOMBRE || '';
    const regex = /^([^\d]+)\s(\d+)$/;
    const match = lastName.trim().match(regex);
    if (match) {
      const baseText = match[1].trim();
      const nextNumber = parseInt(match[2], 10) + 1;
      return `${baseText} ${nextNumber}`;
    }
    return 'Opción 1';
  }

  callIntegrationProcedure(payload) {
    const inputParams = {
      data: {
        SlipId: this.recordId,
        [this.responseNode]: payload
      }
    };

    const options = { chainable: false, useFuture: false };

    const ipConfig = {
      sClassName: 'IntegrationProcedureService',
      sMethodName: 'Slip_ActualizarSlip',
      input: inputParams,
      options: JSON.stringify(options)
    };

    this.omniRemoteCall(ipConfig, true)
      .then(() => {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Slip actualizado',
          message: '',
          variant: 'success'
        }));
      })
      .catch(error => {
        console.error('Error al ejecutar IP:', error);
      });
  }

  handleSave(event) {
    const updates = event.detail.draftValues;
    this.draftValues = [];

    const castByType = (key, value) => {
      const schema = this.fieldSchema[key];
      if (!schema) return value;
      if (value === '' || value === undefined || value === null) return null;
      switch (schema.type) {
        case 'date':
        case 'datetime': // 👈 ahora también procesamos datetime
          return this._toIsoDate(value);
        case 'number':
        case 'currency':
        case 'percent':
          {
            const n = Number(value);
            return Number.isNaN(n) ? null : n;
          }
        case 'boolean':
          return value === true || value === 'true' || value === 1 || value === '1';
        default:
          return value;
      }
    };

    const updatesById = {};
    updates.forEach(u => {
      if (u.Id) updatesById[u.Id] = { ...(updatesById[u.Id] || {}), ...u };
    });

    this.data = this.data.map(row => {
      const update = updatesById[row.Id];
      if (!update) return row;
      const merged = { ...row, ...update };
      const cleaned = Object.keys(merged).reduce((acc, key) => {
        acc[key] = castByType(key, merged[key]);
        return acc;
      }, {});
      const { Id, NOMBRE, OriginalId, ...rest } = cleaned;
      const out = { Id, NOMBRE, ...rest };
      if (OriginalId) out.OriginalId = OriginalId;
      return out;
    });

    // Actualiza bandera y payload
    this._updateCompletenessStatus();
    const payloadToSend = this._mapDataForOutbound(this.data);
    this.omniApplyCallResp({ [this.responseNode]: payloadToSend });
    this.callIntegrationProcedure(payloadToSend);
  }

  handleRowAction(event) {
    const rowId = event.detail.row.Id;
    const actionName = event.detail.action.name;

    if (actionName === 'delete') {
      // Eliminar fila
      this.data = this.data.filter(row => row.Id !== rowId);
    } else if (actionName === 'moveUp' || actionName === 'moveDown') {
      // Mover fila arriba/abajo
      const newData = [...this.data];
      const index = newData.findIndex(row => row.Id === rowId);
      if (actionName === 'moveUp' && index > 0) {
        [newData[index - 1], newData[index]] = [newData[index], newData[index - 1]];
        this.data = newData;
      } else if (actionName === 'moveDown' && index < newData.length - 1) {
        [newData[index + 1], newData[index]] = [newData[index + 1], newData[index]];
        this.data = newData;
      }

      // Opcional: actualizar campo Ordenamiento para reflejar el nuevo orden
      this.data = this.data.map((row, i) => ({
        ...row,
        Ordenamiento: i + 1
      }));
    }

    // Actualiza bandera interna (OmniScript usa esto para bloquear siguiente step si falta)
    this._updateCompletenessStatus();

    // Empujar payload al OmniScript
    const payloadToSend = this._mapDataForOutbound(this.data);
    this.omniApplyCallResp({ [this.responseNode]: payloadToSend });

    // Persistir cambios en el IP (sin mostrar toast aquí)
    this.callIntegrationProcedure(payloadToSend);
  }

  handleRowSelection(event) {
    // Obtener los Ids seleccionados
    const selectedIds = new Set(event.detail.selectedRows.map(r => r.Id));

    // Filtrar las filas seleccionadas
    const selectedRows = this.data.filter(row => selectedIds.has(row.Id));

    // Empujar payload de seleccionados al OmniScript
    const payloadToSend = this._mapDataForOutbound(selectedRows);
    this.omniApplyCallResp({ [this.responseNode]: payloadToSend });

    // Actualizar bandera interna (OmniScript usa esto para bloquear siguiente step si falta)
    this._updateCompletenessStatus();

    // Persistir cambios en el IP (sin mostrar toast aquí)
    this.callIntegrationProcedure(payloadToSend);
  }

handlePicklistChange(event) {
    const { value, context } = event.detail;

    // Convertimos a entero inmediatamente, el 10 es para asegurar base decimal
    const numericValue = value ? parseInt(value, 10) : 0;
    
    // Actualizamos el array 'data' usando la variable numericValue
    this.data = this.data.map(row => {
        if (row.Id === context) {
            // AQUÍ es donde usamos numericValue para asegurar que sea entero
            return { ...row, pjeContrato: numericValue };
        }
        return row; 
    });

    // Notificamos al OmniScript y ejecutamos el IP de guardado
    const payloadToSend = this._mapDataForOutbound(this.data);
    this.omniApplyCallResp({ [this.responseNode]: payloadToSend });
    this.callIntegrationProcedure(payloadToSend);
}

  _mapDataForOutbound(rows) {
  return (rows || []).map(r => {
    const copy = { ...r };

    // Normalizar campos tipo date o date-local → recortar a YYYY-MM-DD
    Object.keys(this.fieldSchema).forEach(key => {
      const schema = this.fieldSchema[key];
      if (schema && (schema.type === 'date' || schema.type === 'date-local') && copy[key]) {
        if (typeof copy[key] === 'string') {
          // Si viene como ISO con hora (ej: 2025-12-02T15:30:00Z), recortar
          copy[key] = copy[key].substring(0, 10);
        } else if (copy[key] instanceof Date && !Number.isNaN(copy[key].getTime())) {
          // Si viene como objeto Date, usar UTC para evitar desfase
          const yyyy = copy[key].getUTCFullYear();
          const mm = String(copy[key].getUTCMonth() + 1).padStart(2, '0');
          const dd = String(copy[key].getUTCDate()).padStart(2, '0');
          copy[key] = `${yyyy}-${mm}-${dd}`;
        }
      }
    });

    // Restaurar Id original si existe
    if (copy.OriginalId !== undefined) {
      copy.Id = copy.OriginalId;
      delete copy.OriginalId;
    }

    return copy;
  });
}

  // === VALIDACIÓN ===

  _isFieldFilled(key, value) {
    const schema = this.fieldSchema[key] || { type: 'text' };

    if (value === undefined || value === null) return false;

    switch (schema.type) {
      case 'text':
        return String(value).trim() !== '';
      case 'number':
      case 'currency':
      case 'percent':
        return typeof value === 'number' && !Number.isNaN(value);
      case 'boolean':
        return typeof value === 'boolean';
      case 'date':
        return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value);
      default:
        return String(value).trim() !== '';
    }
  }

  _isRowComplete(row) {
    if (this.responseNode !== 'Coberturas') return true;
    return Object.entries(this.requiredFieldsCoberturas)
      .every(([key, rule]) => !rule.required || this._isFieldFilled(key, row[key]));
  }

  _getMissingFields(row) {
    if (this.responseNode !== 'Coberturas') return [];
    return Object.entries(this.requiredFieldsCoberturas)
      .filter(([key, rule]) => rule.required && !this._isFieldFilled(key, row[key]))
      .map(([key]) => key);
  }

  _isAllComplete(rows = this.data) {
    const list = rows || [];
    return list.length > 0 && list.every(r => this._isRowComplete(r));
  }

  _updateCompletenessStatus() {
    if (this.responseNode !== 'Coberturas') return;

    const rows = this.data || [];
    const allComplete = this._isAllComplete(rows);

    // Siempre mandar bandera al OmniScript
    this.omniApplyCallResp({
      CoberturasCompletadas: allComplete
    });
  }

  _notifyIncomplete() {
    // Mensaje discreto para el usuario (puedes ajustar el texto)
    this.dispatchEvent(new ShowToastEvent({
      title: 'Faltan datos obligatorios',
      message: 'Completa todas las coberturas antes de actualizar el Slip.',
      variant: 'warning'
    }));
  }
}