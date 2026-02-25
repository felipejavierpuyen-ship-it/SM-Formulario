import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FlexcardWrapperReusable extends OmniscriptBaseMixin(LightningElement) {
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

  @track data = [];
  @track draftValues = [];
  @track isOpen = true;
  @track selectedRowIds = [];

  columns = [];

  get iconName() {
    return this.isOpen ? 'utility:switch' : 'utility:chevronright';
  }

  toggleSection() {
    this.isOpen = !this.isOpen;
  }

connectedCallback() {
  console.log('entro--', this.title, this.responseNode);

  // Paso 1: Filtrar
  const filtered = this.applyFilter(this.records, this.filterBy);

  // Paso 2: Normalizar y ordenar por Ordenamiento ascendente
  const normalized = Array.isArray(filtered)
    ? filtered
        .map(row => {
          const cloned = { ...row };

          // Deserializar AtributosAdicionales si es string
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
        .sort((a, b) => {
          const aVal = parseInt(a.Ordenamiento);
          const bVal = parseInt(b.Ordenamiento);
          return aVal - bVal;
        })
    : [];

  // Paso 3: Construir this.data con lógica de NOMBRE secuencial
  this.data = normalized.map((row, index) => {
    let idValue = row.Id || `row-${Date.now()}-${index}`;
    let nombreValue = row.NOMBRE;

    if (this.areRecordsOptions && !nombreValue) {
      const previous = index > 0 ? normalized[index - 1].NOMBRE || '' : '';
      const regex = /^([^\d]+)\s(\d+)$/;
      const match = previous.trim().match(regex);

      if (match) {
        const baseText = match[1].trim();
        const nextNumber = parseInt(match[2]) + 1;
        nombreValue = `${baseText} ${nextNumber}`;
      } else {
        nombreValue = `Opción ${index + 1}`;
      }
    }

    const { Id, NOMBRE, CATEGORIA, ...rest } = row;
    const formattedRow = {
      Id: idValue,
      NOMBRE: nombreValue || NOMBRE,
      ...(CATEGORIA !== undefined ? { CATEGORIA } : {}),
      ...rest
    };

    return formattedRow;
  });

  // Paso 4: Generar columnas
  this.generateColumns();

  // Paso extra: inicializar IF_Seleccionado y selección visual
  if (this.allowRowSelection) {
    this.data = this.data.map(r => ({
      ...r,
      IF_Seleccionado: r.IF_Seleccionado === true ? true : false
    }));

    this.selectedRowIds = this.data
      .filter(r => r.IF_Seleccionado)
      .map(r => r.Id);

    // Guardar todos al cargar con IF_Seleccionado
    if (this.isFromProductCatalog) {
      this.omniApplyCallResp({ [this.responseNode]: this.data });
      this.callIntegrationProcedure(this.data);
    }
  }

  // Paso 5: Aplicar respuesta si viene de catálogo y no hay selección de filas
  if (this.isFromProductCatalog && !this.allowRowSelection) {
    this.omniApplyCallResp({ [this.responseNode]: this.data });
    this.callIntegrationProcedure(this.data);
  }
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
    if (!this.data.length) return;

    const sampleRow = this.data[0];
    const allKeys = Object.keys(sampleRow).filter(k => k !== 'Id');

    const reorderedKeys = allKeys.includes('NOMBRE')
      ? ['NOMBRE', ...allKeys.filter(k => k !== 'NOMBRE')]
      : allKeys;

    this.columns = reorderedKeys
      .filter(key => !this.hiddenColumns.includes(key))
      .map(key => ({
        label: key === 'NOMBRE' ? 'Nombre' : key,
        fieldName: key,
        editable: true,
        type: 'text'
      }));

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
  if (!this.columns.length) return;

  const newRow = {};
  this.columns.forEach(col => {
    if (col.fieldName !== 'deleteRow') {
      newRow[col.fieldName] = '';
    }
  });

  const totalRows = this.data.length;
  newRow.Id = `row-${Date.now()}`;

  let nombreValue;
  if (this.allowRowSelection) {
    // Nuevo nombre por defecto: Cobertura n
    nombreValue = `Cobertura ${totalRows + 1}`;
  } else {
    // Lógica original
    nombreValue = this.generateNextName();
  }

  let formattedRow = {
    Id: newRow.Id,
    NOMBRE: nombreValue,
    ...Object.fromEntries(
      Object.entries(newRow).filter(([key]) => key !== 'Id' && key !== 'NOMBRE')
    )
  };

  // Si selección está habilitada → EsOpcional = true y IF_Seleccionado = false
  if (this.allowRowSelection) {
    formattedRow.EsOpcional = true;
    formattedRow.IF_Seleccionado = false;
  } else if (this.responseNode === 'Coberturas') {
    // Lógica original para Coberturas sin selección
    formattedRow.EsOpcional = false;
  }

  this.data = [...this.data, formattedRow];

}

  generateNextName() {
    if (!this.data.length) return 'Opción 1';

    const lastName = this.data[this.data.length - 1].NOMBRE || '';
    const regex = /^([^\d]+)\s(\d+)$/;
    const match = lastName.trim().match(regex);

    if (match) {
      const baseText = match[1].trim();
      const nextNumber = parseInt(match[2]) + 1;
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

    const options = {
      chainable: false,
      useFuture: false
    };

    const ipConfig = {
      sClassName: 'IntegrationProcedureService',
      sMethodName: 'Slip_ActualizarSlip',
      input: inputParams,
      options: JSON.stringify(options)
    };

    this.omniRemoteCall(ipConfig, true)
      .then(response => {
        console.log('Integration Procedure ejecutado:', response);
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Slip actualizado',
            message: '',
            variant: 'success'
          })
        );
      })
      .catch(error => {
        console.error('Error al ejecutar IP:', error);
      });
  }

  handleSave(event) {
    const updates = event.detail.draftValues;
    this.draftValues = [];

    this.data = this.data.map(row => {
      const update = updates.find(d => d.Id === row.Id);
      const updatedRow = update ? { ...row, ...update } : row;
      const { Id, NOMBRE, ...rest } = updatedRow;
      return { Id, NOMBRE, ...rest };
    });

    this.omniApplyCallResp({ [this.responseNode]: this.data });
    this.callIntegrationProcedure(this.data);
  }

  handleRowAction(event) {
    const rowId = event.detail.row.Id;
    const actionName = event.detail.action.name;

    if (actionName === 'delete') {
      this.data = this.data.filter(row => row.Id !== rowId);
    } else if (actionName === 'moveUp' || actionName === 'moveDown') {
      let newData = [...this.data];
      const index = newData.findIndex(row => row.Id === rowId);

      if (actionName === 'moveUp' && index > 0) {
        [newData[index - 1], newData[index]] = [newData[index], newData[index - 1]];
        this.data = newData;
      } else if (actionName === 'moveDown' && index < newData.length - 1) {
        [newData[index + 1], newData[index]] = [newData[index], newData[index + 1]];
        this.data = newData;
      }
    }

    this.omniApplyCallResp({ [this.responseNode]: this.data });
    this.callIntegrationProcedure(this.data);
  }

  handleRowSelection(event) {
    // Si no está habilitada la selección, no alteramos el comportamiento
    if (!this.allowRowSelection) {
      return;
    }

    const selectedIds = new Set(event.detail.selectedRows.map(r => r.Id));

    // Construir array completo con IF_Seleccionado para cada registro
    const updatedData = this.data.map(row => ({
      ...row,
      IF_Seleccionado: selectedIds.has(row.Id)
    }));

    // Actualizar selección visual (por si algún otro flujo depende de ello)
    this.selectedRowIds = [...selectedIds];

    // Enviar todo el array con el nodo IF_Seleccionado
    this.omniApplyCallResp({ [this.responseNode]: updatedData });
    this.callIntegrationProcedure(updatedData);
  }
}