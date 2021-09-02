import Axios, { AxiosRequestConfig, AxiosResponse } from 'axios';
import camelize from 'camelize';
import _ from 'lodash';
import { useQueryClient } from 'react-query';
import snakeize from 'snakeize';

export const API_QUERY_KEY = 'API_QUERY_KEY';

export function useInvalidateApiQueries() {
  const queryClient = useQueryClient();
  return () => {
    queryClient.invalidateQueries(API_QUERY_KEY);
  };
}

const axiosRequestConfig: AxiosRequestConfig = {
  baseURL: `http://localhost:7000/`,
  responseType: 'json',
  withCredentials: false,
};

const snakeizeJsonRequest = (request: AxiosRequestConfig) => {
  const { data, headers } = request;
  const isJson = !headers || headers['Content-Type'] === 'application/json';
  if (data && isJson) {
    return { ...request, data: snakeize(data) };
  } else {
    return request;
  }
};

const camelizeResponse = (response: AxiosResponse) => {
  if (_.has(response, 'data')) {
    return { ...response, data: camelize(response.data) };
  }
  return response;
};

const api = Axios.create(axiosRequestConfig);
api.interceptors.request.use(snakeizeJsonRequest);
api.interceptors.response.use(camelizeResponse);

export default api;
