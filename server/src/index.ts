import { handleRequest, type Env } from "./app";
export default {
  fetch(request: Request, env: Env) {
    return handleRequest(request, env);
  },
};
