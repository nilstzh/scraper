# Scraper

This repo content is a part of Dotidot technical assignment.

## Install

```sh
cp .env.example .env
export $(cat .env | xargs)

bundle install
rails dev:cache # optional, enables caching in dev environment
```

## Run the server

```sh
rails server
```

## Run tests

```
rails test
```

## Description

This a simple Rails api-only application. It can scrap data from web pages based on
- css selectors,
- meta tags `name` values.

## Endpoint

#### GET `/data`

**Request Parameters**
- `url`: `required` String - web page URL for scraping
- `fields`: `required` Object - where keys are arbitrary names of fields and values are CSS selectors for scraping
  - `fields.meta`: `optional` List - list of strings with meta tags "names" to scrap

**Request Example**

```sh
curl -X GET "http://localhost:3000/data" \
        -H "Content-Type: application/json" \
        -d '{
      "url": "https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm",
      "fields": {
        "price": ".price-box__price",
        "rating_count": ".ratingCount",
        "rating_value": ".ratingValue",
        "meta": ["keywords", "twitter:image"]
      }
    }'
```

**Response Example**

```json
{
  "price":"20 990,-",
  "rating_count":"16 hodnocení",
  "rating_value":"4,8",
  "meta":{
    "keywords":"AEG,7000,ProSteam®,LFR73964CC,Automatické pračky,Automatické pračky AEG,Chytré pračky,Chytré pračky AEG",
    "twitter:image":"https://image.alza.cz/products/AEGPR065/AEGPR065.jpg?width=360\u0026height=360"
  }
}
```

## Implementation details

- This application supports `httparty` and `selenium` as client options (either can be set as `HTTP_CLIENT` ENV variable). Originally I implemented Selenium version because my requests with HTTParty were blocked by some bot detection. However later I found out that from different IP HTTParty works as well, so I implemented it too and use it as default for performance reasonse.

- Current caching implementation uses `:memory_store` for simplicity. But in real production environment that would need to be changed (e.g. to Redis) to handle larger datasets and ensure persistence.

- Cache expiration time is set to 1 hour. It could be ajusted depending on requirements.

- Currently, if Selenium WebDriver is chosen as client, new instance opened for every request. This isn't efficient. To optimize it WebDriver should be reused across multiple requests.

- Further speed and efficency improvement could be accieved by handling scraping in parallel, which could be done with background job processing.
