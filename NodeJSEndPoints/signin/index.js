const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  ScanCommand,
} = require("@aws-sdk/lib-dynamodb");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const dynamoDbClient = new DynamoDBClient({ region: "eu-north-1" });
const ddbDocClient = DynamoDBDocumentClient.from(dynamoDbClient);
const JWT_SECRET_KEY = "JWT_SECRET_KEY";

exports.handler = async (event) => {
  const { email, password } = JSON.parse(event.body);

  const params = {
    TableName: "Users",
    FilterExpression: "email = :email",
    ExpressionAttributeValues: {
      ":email": email,
    },
  };

  try {
    const result = await ddbDocClient.send(new ScanCommand(params));
    if (result.Items.length === 0) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: "Invalid email or password" }),
      };
    }

    const user = result.Items[0];
    const passwordValid = await bcrypt.compare(password, user.password);
    if (!passwordValid) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: "Invalid email or password" }),
      };
    }

    const token = jwt.sign({ userId: user.id }, JWT_SECRET_KEY, {
      expiresIn: "5h",
    });

    return {
      statusCode: 200,
      body: JSON.stringify({ token }),
    };
  } catch (error) {
    console.error("Error: ", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal server error" }),
    };
  }
};