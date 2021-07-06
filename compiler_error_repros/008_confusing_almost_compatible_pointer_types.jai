#import "Basic";

// struggling to repro this issue
// originated in sql_insert
/*
In workspace #4 ("jai-record_specs"):
/workspace/src/sql/sql_insert.jai:65,37: Error: Internal compiler error: Got a -1 emit result, but the expression's size was nonzero.

    expression_string := sprint("INSERT INTO % % RETURNING id;", into, Insert.SQL_EXPRESSION);
    args := Insert.to_sql_insert_args(insert);
*/
// fixed by changing from
// to_sql_insert_args :: (insertable_fields: *InsertableFields) -> [..]Any {
// to 
// to_sql_insert_args :: (insertable_fields: *$T) -> [..]Any {

// the same thing happened with sql_update, in the comparable procedure

ContainerType :: struct($T: Type, $procedure: (*T) -> string) {
  using contained: *T;
}

ContainedType :: struct {
  value: string;
}

procedure_consuming_a_pointer :: (contained: *ContainedType) -> string {
  #insert #run sprint("return contained.%;\n", type_info(ContainedType).members[0].name);
};

main :: () {
  ConcreteContainerType :: ContainerType(ContainedType, procedure_consuming_a_pointer);
  container: ConcreteContainerType;
  contained: ContainedType;
  contained.value = "hello";
  container.contained = *contained;

  print("result: %\n", ConcreteContainerType.procedure(*container));
}
