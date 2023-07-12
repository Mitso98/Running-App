const { DynamoDBClient, ScanCommand, PutItemCommand } = require('@aws-sdk/client-dynamodb');

const bcrypt = require("bcryptjs");
const { v4: uuidv4 } = require("uuid");

const dynamoDb = new DynamoDBClient({ region: "eu-north-1" });

exports.handler = async (event) => {
  const {
    name,
    email,
    password,
    confirmPassword,
    height,
    weight,
    age,
    gender,
  } = JSON.parse(event.body);

  if (password !== confirmPassword) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Passwords do not match" }),
    };
  }

  // Check if email is already registered
  const scanParams = {
    TableName: "Users",
    FilterExpression: "email = :email",
    ExpressionAttributeValues: {
      ":email": { S: email },
    },
  };

  const { Items } = await dynamoDb.send(new ScanCommand(scanParams));

  if (Items && Items.length > 0) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Email already registered" }),
    };
  }

  const hashedPassword = bcrypt.hashSync(password, 10);

  const params = {
    TableName: "Users",
    Item: {
      id: { S: uuidv4() },
      name: { S: name },
      email: { S: email },
      password: { S: hashedPassword },
      height: { N: height.toString() },
      weight: { N: weight.toString() },
      age: { N: age.toString() },
      gender: { S: gender },
    },
  };

  try {
    await dynamoDb.send(new PutItemCommand(params));
    return {
      statusCode: 200,
      body: JSON.stringify({ message: "User registered successfully" }),
    };
  } catch (error) {
    console.error("Error: ", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal server error" }),
    };
  }
};
