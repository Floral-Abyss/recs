--!strict

export type ComponentClass = {
    className: string,
    entityFilter: (EntityId) -> boolean,
    __index: ComponentClass,
    _create: any,
}

export type ComponentIdentifier = ComponentClass | string

export type ClassName = string

export type EntityId = string | number | Instance

export type StepperDefinition = {
    type: string,
    [string]: any?,
}

export type Steppers = { [number]: StepperDefinition }

return nil
