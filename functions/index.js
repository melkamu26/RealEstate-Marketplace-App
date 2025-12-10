require("dotenv").config();
const functions = require("firebase-functions");
const fetch = require("node-fetch");


// MAIN LISTINGS
exports.getListings = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");

  const apiKey = process.env.REALTY_API_KEY;

  try {
    const response = await fetch(
      "https://realty-in-us.p.rapidapi.com/properties/v3/list",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-rapidapi-key": apiKey,
          "x-rapidapi-host": "realty-in-us.p.rapidapi.com",
        },
        body: JSON.stringify({
          limit: 50,
          offset: 0,
          postal_code: "90004",
          status: ["for_sale", "ready_to_build"],
          sort: { direction: "desc", field: "list_date" }
        }),
      }
    );

    const data = await response.json();
    res.status(200).send(data);

  } catch (err) {
    res.status(500).send({ error: err.toString() });
  }
});


// SEARCH PROPERTIES (Advanced Search)
exports.searchProperties = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");

  const apiKey = process.env.REALTY_API_KEY;
  const { city, maxPrice } = req.query;

  try {
    const response = await fetch(
      "https://realty-in-us.p.rapidapi.com/properties/v3/list",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-rapidapi-key": apiKey,
          "x-rapidapi-host": "realty-in-us.p.rapidapi.com",
        },
        body: JSON.stringify({
          limit: 50,
          offset: 0,
          city: city,
          price_max: maxPrice ? Number(maxPrice) : undefined,
        }),
      }
    );

    const data = await response.json();
    res.status(200).send(data);

  } catch (err) {
    res.status(500).send({ error: err.toString() });
  }
});

// ------------------------------
// PROPERTY GALLERY (Correct Endpoint)
// ------------------------------
exports.getPropertyPhotos = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");

  const apiKey = process.env.REALTY_API_KEY;
  const propertyId = req.query.property_id;

  if (!propertyId) {
    return res.status(400).send({ error: "property_id is required" });
  }

  try {
    const response = await fetch(
      `https://realty-in-us.p.rapidapi.com/properties/v3/get-photos?property_id=${propertyId}`,
      {
        method: "GET",
        headers: {
          "x-rapidapi-host": "realty-in-us.p.rapidapi.com",
          "x-rapidapi-key": apiKey
        }
      }
    );

    const data = await response.json();
    res.status(200).send(data);

  } catch (err) {
    res.status(500).send({ error: err.toString() });
  }
});


// PROPERTY DETAILS

exports.getPropertyDetails = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");

  res.status(200).send({ message: "Deprecated. Use getPropertyPhotos instead." });
});
