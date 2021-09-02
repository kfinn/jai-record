import { Link } from "react-router-dom";

export default function Nav() {
  return <nav>
    <ul>
      <li><Link to="/">Home</Link></li>
      <li><Link to="/users">Users</Link></li>
    </ul>
  </nav>;
}
