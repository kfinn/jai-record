import _ from "lodash";
import { Suspense } from "react";
import { BrowserRouter, Route, Switch } from "react-router-dom";
import { RecoilRoot } from "recoil";
import Nav from "./Nav";
import UsersIndex from "./UsersIndex/UsersIndex";
import UsersShow from "./UsersShow/UsersShow";

function App() {
  return <RecoilRoot>
    <BrowserRouter>
      <Nav />
      <Suspense fallback={<div>loading...</div>}>
        <Switch>
          <Route exact path="/">
            <h1>Todos</h1>
            <div>Pick a nav item above</div>
          </Route>
          <Route path="/users">
            <Switch>
              <Route exact path="/users">
                <UsersIndex />
              </Route>
              <Route path ="/users/:id" render={({ match: { params: { id } } }) => <UsersShow id={_.parseInt(id)} />}/>
            </Switch>
          </Route>
        </Switch>
      </Suspense>
    </BrowserRouter>
  </RecoilRoot>
}

export default App;
