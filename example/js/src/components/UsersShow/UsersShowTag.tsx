import { useRecoilValue, useRecoilValueLoadable } from "recoil"
import tagState from "../../state/tagState";

export default function UsersShowTag({ id }: { id: number }) {
  const tag = useRecoilValue(tagState(id));

  return <div>{tag.description}</div>
}
