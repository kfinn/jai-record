import { Link } from "react-router-dom";
import { useRecoilValue } from "recoil";
import userState from "../../state/userState";

export default function UsersIndexItem({ id }: { id: number }) {
  const user = useRecoilValue(userState(id))

  return <div>
    <Link to={`/users/${user.id}`}>
      {user.email}
      ({user.id})
    </Link>
  </div>
}
